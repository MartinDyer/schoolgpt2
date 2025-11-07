// src/lib/session.js
// In-memory session & context helpers (unchanged logic)

const SESSIONS = new Map();
const MAX_MESSAGES = 100;
const MAX_CHARS = 35000;

const SYSTEM_PROMPT =
  "You are SchoolSafeAI, a helpful, safe assistant for a K-12 school. Be concise, factual, and age-appropriate. If a request is unsafe or not allowed, explain why and offer safer alternatives.";

function keyFor(userId, sessionId) {
  return `${userId || "anonymous"}::${sessionId || "default"}`;
}

function getSession(key) {
  if (!SESSIONS.has(key)) {
    SESSIONS.set(key, { messages: [], updatedAt: Date.now() });
  }
  return SESSIONS.get(key);
}

function trimSession(session) {
  if (session.messages.length > MAX_MESSAGES) {
    session.messages = session.messages.slice(-MAX_MESSAGES);
  }
  let total = 0;
  for (let i = session.messages.length - 1; i >= 0; i--) {
    total += session.messages[i].content.length;
    if (total > MAX_CHARS) {
      session.messages = session.messages.slice(i + 1);
      break;
    }
  }
}

function addMsg(key, role, content) {
  const s = getSession(key);
  s.messages.push({ role, content });
  s.updatedAt = Date.now();
  trimSession(s);
}

function buildContextMessages(sessionMsgs, userPrompt, enhancedPrompt) {
  const msgs = [{ role: "system", content: SYSTEM_PROMPT }, ...sessionMsgs];
  msgs.push({ role: "user", content: `Original user prompt:\n${userPrompt}` });
  msgs.push({ role: "user", content: `Enhanced prompt:\n${enhancedPrompt}` });
  return msgs;
}

module.exports = {
  SESSIONS,
  MAX_MESSAGES,
  MAX_CHARS,
  SYSTEM_PROMPT,
  keyFor,
  getSession,
  addMsg,
  trimSession,
  buildContextMessages,
};
