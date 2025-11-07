// /src/routes/shareRoutes.js
const express = require("express");
const { findOwnedChat, sql, sqlPool } = require("../lib/db");

const router = express.Router();

// --------------------- LINK SHARING ---------------------
router.post("/chats/share-link", async (req, res) => {
  try {
    const userId = String(req.body?.userId || "");
    const sessionId = req.body?.sessionId ? String(req.body.sessionId) : null;
    const chatId = req.body?.chatId || null;
    if (!userId) return res.status(400).json({ ok: false, error: "userId required" });

    const chat = await findOwnedChat({ userId, chatId, sessionId });
    if (!chat) return res.status(404).json({ ok: false, error: "chat_not_found_for_owner" });

    const token = require("crypto").randomUUID().replace(/-/g, "");
    await sqlPool()
      .request()
      .input("token", sql.NVarChar(64), token)
      .input("chatId", sql.UniqueIdentifier, chat.id)
      .input("ownerUserId", sql.NVarChar(255), userId)
      .query(`
        INSERT INTO [dbo].[ShareLinks] ([token],[chatId],[ownerUserId])
        VALUES (@token,@chatId,@ownerUserId)
      `);

    console.log(`[SQL] SHARELINK created token=${token} chat=${chat.id} owner=${userId}`);
    return res.json({ ok: true, token });
  } catch (err) {
    console.error("[SQL] SHARELINK create error:", err?.message || err);
    return res.status(500).json({ ok: false, error: "share_link_failed" });
  }
});

router.get("/share/:token", async (req, res) => {
  try {
    const token = req.params.token;
    const r = await sqlPool()
      .request()
      .input("token", sql.NVarChar(64), token)
      .query(`
        SELECT TOP 1 s.ownerUserId, s.chatId, c.*
        FROM [dbo].[ShareLinks] s
        INNER JOIN [dbo].[Chats] c ON c.[id] = s.[chatId]
        WHERE s.[token] = @token
      `);
    const row = r.recordset[0];
    if (!row) return res.status(404).json({ ok: false, error: "invalid_share_token" });

    console.log(`[SQL] SHARELINK fetch token=${token} chat=${row.chatId} owner=${row.ownerUserId}`);

    return res.json({
      ok: true,
      ownerUserId: row.ownerUserId,
      chat: {
        id: row.id,
        title: row.title,
        preview: row.preview,
        messageCount: row.messageCount,
        messages: row.messages,
        sessionId: row.sessionId,
        updatedAt: row.updatedAt,
        createdAt: row.createdAt,
      },
    });
  } catch (err) {
    console.error("[SQL] SHARELINK get error:", err?.message || err);
    return res.status(500).json({ ok: false, error: "share_get_failed" });
  }
});

module.exports = router;
