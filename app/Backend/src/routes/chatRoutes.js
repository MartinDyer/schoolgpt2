// /src/routes/chatRoutes.js
const express = require("express");
const { randomUUID } = require("crypto");

const {
  SESSIONS,
  keyFor,
  getSession,
  addMsg,
  buildContextMessages,
} = require("../lib/session");

const {
  axios,
  chatUrl,
  getHeaders,
  refusalText,
  isContentFilterErr,
  choiceFiltered,
} = require("../lib/openai");

const {
  upsertChat,
  insertFlagged,
  listChats,
  getChat,
  ensureSessionHydrated,
} = require("../lib/db");

const { enhancerSystemPrompt } = require("../lib/prompt");

const router = express.Router();

const ts = () => new Date().toISOString();

// X-Request-Id for router (keeps parity with server.js behavior)
router.use((req, res, next) => {
  if (!req.requestId) req.requestId = randomUUID();
  next();
});

// ----- helper for blocked replies (kept here to avoid circular deps)
function replyBlockedAndRecord(res, reqId, sessKey, phase, detail, userPrompt, enhancedPromptOrNull) {
  console.warn(`[${ts()}] [${reqId}] ${phase} FILTERED`, detail?.error || detail);
  if (userPrompt) addMsg(sessKey, "user", `Original user prompt:\n${userPrompt}`);
  if (enhancedPromptOrNull) addMsg(sessKey, "user", `Enhanced prompt:\n${enhancedPromptOrNull}`);
  addMsg(sessKey, "assistant", refusalText);
  return res.status(200).json({
    ok: true,
    requestId: reqId,
    reply: refusalText,
    enhancedPrompt: enhancedPromptOrNull,
    usage: {},
    latencyMs: 0,
    blocked: true,
    reason: "content_filter",
  });
}

// --------------------- CHAT HISTORY API ---------------------
router.post("/chats/save", async (req, res) => {
  try {
    const userId = (req.body?.userId || "").toString();
    const sessionId = (req.body?.sessionId || "").toString();
    const messages = Array.isArray(req.body?.messages) ? req.body.messages : [];
    const explicitTitle = req.body?.title;

    if (!userId || !sessionId) {
      return res.status(400).json({ ok: false, error: "userId and sessionId are required" });
    }
    const id = await upsertChat({ userId, sessionId, messages, explicitTitle });
    return res.json({ ok: true, id });
  } catch (err) {
    console.error("[SQL] SAVE error:", err?.message || err);
    return res.status(500).json({ ok: false, error: "save_failed" });
  }
});

router.get("/chats", async (req, res) => {
  try {
    const userId = (req.query.userId || "").toString();
    if (!userId) return res.status(400).json({ ok: false, error: "userId required" });
    const items = await listChats(userId);
    return res.json({ ok: true, items });
  } catch (err) {
    console.error("[SQL] LIST error:", err?.message || err);
    return res.status(500).json({ ok: false, error: "list_failed" });
  }
});

router.get("/chats/:id", async (req, res) => {
  try {
    const userId = (req.query.userId || "").toString();
    const id = req.params.id;
    if (!userId) return res.status(400).json({ ok: false, error: "userId required" });
    const row = await getChat(userId, id);
    if (!row) return res.status(404).json({ ok: false, error: "not_found" });

    // Hydrate memory so next /api/chat uses full context immediately
    try {
      const stored = JSON.parse(row.messages || "[]");
      SESSIONS.set(keyFor(userId, row.sessionId), { messages: stored, updatedAt: Date.now() });
      console.log(`[SQL] HYDRATE on open: user=${userId} session=${row.sessionId} (${stored.length} msgs)`);
    } catch { }

    return res.json({ ok: true, chat: row });
  } catch (err) {
    console.error("[SQL] GET error:", err?.message || err);
    return res.status(500).json({ ok: false, error: "get_failed" });
  }
});

// ====================== /api/chat ==========================
router.post("/chat", async (req, res) => {
  const userPrompt = (req.body?.message || "").toString().trim();
  const userId = req.body?.userId || "anonymous";
  const sessionId = req.body?.sessionId || "default";
  const reqId = req.requestId || "-";
  const sessKey = keyFor(userId, sessionId);

  if (!userPrompt) {
    console.warn(`[${ts()}] [${reqId}] /api/chat - empty prompt`);
    return res.status(200).json({
      ok: true,
      requestId: reqId,
      reply: "Please enter a question so I can help.",
      enhancedPrompt: null,
      usage: {},
      latencyMs: 0,
    });
  }

  console.log("\n====================== /api/chat ======================");
  console.log(`[${ts()}] [${reqId}] userId=${userId} sessionId=${sessionId}`);
  console.log(`[${ts()}] [${reqId}] USER PROMPT:\n${userPrompt}\n`);

  try {
    const t0 = Date.now();

    // 1) Enhance (system prompt now comes from src/lib/prompt.js)
    let enhancedPrompt = userPrompt;

    // Fetch headers (Managed Identity or Key)
    const requestHeaders = await getHeaders();

    if (true) { // Always try to enhance if configured (headers check is now implicit)
      const enhancerMessages = [
        { role: "system", content: enhancerSystemPrompt },
        { role: "user", content: userPrompt },
      ];
      try {
        const enhanceResp = await axios.post(
          chatUrl,
          { messages: enhancerMessages, temperature: 0.2, max_tokens: 300 },
          { headers: requestHeaders, timeout: 60000 }
        );
        const enhChoice = enhanceResp?.data?.choices?.[0];
        if (choiceFiltered(enhChoice)) {
          await insertFlagged({
            userId,
            sessionId,
            phase: "ENHANCE",
            originalPrompt: userPrompt,
            enhancedPrompt: null,
            reason: "content_filter",
            detail: enhChoice?.content_filter_results || enhChoice,
            requestId: reqId,
          });
          return replyBlockedAndRecord(
            res,
            reqId,
            sessKey,
            "ENHANCE",
            { finish_reason: enhChoice?.finish_reason, cfr: enhChoice?.content_filter_results },
            userPrompt,
            null
          );
        }
        enhancedPrompt = enhChoice?.message?.content?.trim() || userPrompt;
      } catch (err) {
        if (isContentFilterErr(err)) {
          await insertFlagged({
            userId,
            sessionId,
            phase: "ENHANCE",
            originalPrompt: userPrompt,
            enhancedPrompt: null,
            reason: "policy_violation",
            detail: err?.response?.data || err?.message,
            requestId: reqId,
          });
          return replyBlockedAndRecord(res, reqId, sessKey, "ENHANCE", err.response?.data, userPrompt, null);
        }
        console.error(`[${ts()}] [${reqId}] ENHANCE ERROR:`, err?.response?.data || err.message);
      }
    }

    console.log(`[${ts()}] [${reqId}] ENHANCED PROMPT:\n${enhancedPrompt}\n`);

    // 2) Ensure memory hydrated from DB for this session
    await ensureSessionHydrated(userId, sessionId);
    const { messages: history } = getSession(sessKey);
    const answerMessages = buildContextMessages(history, userPrompt, enhancedPrompt);

    // 3) Ask model OR fallback
    let reply = "I'm here to help you learn! (demo reply)";
    let usage = {};
    if (true) {
      try {
        const answerResp = await axios.post(
          chatUrl,
          { messages: answerMessages, temperature: 0.2 },
          { headers: requestHeaders, timeout: 120000 }
        );
        const ansChoice = answerResp?.data?.choices?.[0];
        if (choiceFiltered(ansChoice)) {
          addMsg(sessKey, "user", `Original user prompt:\n${userPrompt}`);
          addMsg(sessKey, "user", `Enhanced prompt:\n${enhancedPrompt}`);

          await insertFlagged({
            userId,
            sessionId,
            phase: "ANSWER",
            originalPrompt: userPrompt,
            enhancedPrompt,
            reason: "content_filter",
            detail: ansChoice?.content_filter_results || ansChoice,
            requestId: reqId,
          });

          return replyBlockedAndRecord(
            res,
            reqId,
            sessKey,
            "ANSWER",
            { finish_reason: ansChoice?.finish_reason, cfr: ansChoice?.content_filter_results },
            null,
            enhancedPrompt
          );
        }
        reply = ansChoice?.message?.content?.trim() || reply;
        usage = answerResp?.data?.usage || {};
      } catch (err) {
        if (isContentFilterErr(err)) {
          addMsg(sessKey, "user", `Original user prompt:\n${userPrompt}`);
          addMsg(sessKey, "user", `Enhanced prompt:\n${enhancedPrompt}`);

          await insertFlagged({
            userId,
            sessionId,
            phase: "ANSWER",
            originalPrompt: userPrompt,
            enhancedPrompt,
            reason: "policy_violation",
            detail: err?.response?.data || err?.message,
            requestId: reqId,
          });

          return replyBlockedAndRecord(res, reqId, sessKey, "ANSWER", err.response?.data, null, enhancedPrompt);
        }
        console.error(`[${ts()}] [${reqId}] ANSWER ERROR:`, err?.response?.data || err.message);
        reply = "I couldn’t answer that. Please try a different question or rephrase politely.";
      }
    }

    const latencyMs = Date.now() - t0;
    addMsg(sessKey, "user", `Original user prompt:\n${userPrompt}`);
    addMsg(sessKey, "user", `Enhanced prompt:\n${enhancedPrompt}`);
    addMsg(sessKey, "assistant", reply);

    console.log(`[${ts()}] [${reqId}] MODEL RESPONSE:\n${reply}\n`);
    console.log(`[${ts()}] [${reqId}] USAGE:`, usage);
    console.log(`[${ts()}] [${reqId}] TOTAL LATENCY: ${latencyMs} ms`);
    console.log("=======================================================\n");

    return res.status(200).json({ ok: true, requestId: reqId, reply, enhancedPrompt, usage, latencyMs });
  } catch (err) {
    console.error(`[${ts()}] [${req.requestId || "-"}] UNEXPECTED ERROR:`, err);
    addMsg(keyFor(req.body?.userId, req.body?.sessionId), "assistant", "Something went wrong on my side. Please try again.");
    return res.status(200).json({
      ok: true,
      requestId: req.requestId || "-",
      reply: "Something went wrong on my side. Please try again.",
      enhancedPrompt: null,
      usage: {},
      latencyMs: 0,
    });
  }
});

// clear memory session (frontend calls this on "New Chat")
router.post("/chat/clear", (req, res) => {
  const userId = req.body?.userId || "anonymous";
  const sessionId = req.body?.sessionId || "default";
  const k = keyFor(userId, sessionId);
  SESSIONS.delete(k);
  return res.json({ ok: true, cleared: k });
});

module.exports = router;
