// src/lib/db.js
// SQL connection, schema, and DB helpers (unchanged SQL / behavior)

const sql = require("mssql");
const { SESSIONS, keyFor } = require("./session");

const sqlConfig = process.env.SQL_CONNECTION_STRING
  ? process.env.SQL_CONNECTION_STRING
  : {
    user: process.env.AZURE_SQL_USER,
    password: process.env.AZURE_SQL_PASS,
    server: process.env.AZURE_SQL_SERVER,
    database: process.env.AZURE_SQL_DB,
    options: {
      encrypt: true,
      trustServerCertificate: false,
    },
  };

let sqlPool = null;

async function ensureSchema() {
  const TSQL = `
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Chats]') AND type in (N'U'))
BEGIN
  CREATE TABLE [dbo].[Chats] (
    [id] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    [userId] NVARCHAR(255) NOT NULL,
    [sessionId] NVARCHAR(255) NOT NULL,
    [title] NVARCHAR(200) NULL,
    [preview] NVARCHAR(400) NULL,
    [messageCount] INT NOT NULL DEFAULT(0),
    [messages] NVARCHAR(MAX) NOT NULL,
    [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
  CREATE INDEX IX_Chats_User ON [dbo].[Chats] ([userId], [updatedAt] DESC);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FlaggedMessages]') AND type in (N'U'))
BEGIN
  CREATE TABLE [dbo].[FlaggedMessages] (
    [id] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    [userId] NVARCHAR(255) NOT NULL,
    [sessionId] NVARCHAR(255) NOT NULL,
    [phase] NVARCHAR(50) NOT NULL, -- ENHANCE | ANSWER
    [originalPrompt] NVARCHAR(MAX) NOT NULL,
    [enhancedPrompt] NVARCHAR(MAX) NULL,
    [reason] NVARCHAR(100) NULL,
    [detail] NVARCHAR(MAX) NULL,
    [requestId] NVARCHAR(100) NULL,
    [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
  CREATE INDEX IX_Flagged_Time ON [dbo].[FlaggedMessages] ([createdAt] DESC);
  CREATE INDEX IX_Flagged_User ON [dbo].[FlaggedMessages] ([userId], [createdAt] DESC);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ShareLinks]') AND type in (N'U'))
BEGIN
  CREATE TABLE [dbo].[ShareLinks] (
    [id] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    [token] NVARCHAR(64) NOT NULL UNIQUE,
    [chatId] UNIQUEIDENTIFIER NOT NULL,
    [ownerUserId] NVARCHAR(255) NOT NULL,
    [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
  CREATE UNIQUE INDEX UX_ShareLinks_Token ON [dbo].[ShareLinks] ([token]);
  CREATE INDEX IX_ShareLinks_Chat ON [dbo].[ShareLinks] ([chatId]);
END
`;
  await sqlPool.request().batch(TSQL);
  console.log("[SQL] Schema ensured (tables ready).");
}

(async function bootSql() {
  try {
    sqlPool = await sql.connect(sqlConfig);
    console.log("[SQL] Connected to Azure SQL.");
    await ensureSchema();
  } catch (err) {
    console.error("[SQL] Connection error:", err?.message || err);
  }
})();

function deriveTitleAndPreview(messages = []) {
  const firstUser = messages.find((m) => m.role === "user");
  const title = firstUser?.content?.slice(0, 100)?.replace(/\s+/g, " ") || "Untitled chat";
  const lastTwo = messages.slice(-2).map((m) => m.content).join(" ");
  const preview = (lastTwo || firstUser?.content || "").slice(0, 200).replace(/\s+/g, " ");
  const messageCount = messages.length || 0;
  return { title, preview, messageCount };
}

async function upsertChat({ userId, sessionId, messages, explicitTitle }) {
  if (!sqlPool) throw new Error("SQL pool not ready");
  const { title, preview, messageCount } = deriveTitleAndPreview(messages);
  const payload = JSON.stringify(messages || []);
  const now = new Date().toISOString();

  const TSQL = `
DECLARE @existingId UNIQUEIDENTIFIER =
  (SELECT TOP 1 [id] FROM [dbo].[Chats] WHERE [userId] = @userId AND [sessionId] = @sessionId);

IF @existingId IS NULL
BEGIN
  INSERT INTO [dbo].[Chats] ([userId],[sessionId],[title],[preview],[messageCount],[messages],[updatedAt])
  OUTPUT inserted.id
  VALUES (@userId,@sessionId,@title,@preview,@messageCount,@messages,@updatedAt);
END
ELSE
BEGIN
  UPDATE [dbo].[Chats]
  SET [title] = @title,
      [preview] = @preview,
      [messageCount] = @messageCount,
      [messages] = @messages,
      [updatedAt] = @updatedAt
  WHERE [id] = @existingId;
  SELECT @existingId AS id;
END
`;
  const r = await sqlPool
    .request()
    .input("userId", sql.NVarChar(255), userId)
    .input("sessionId", sql.NVarChar(255), sessionId)
    .input("title", sql.NVarChar(200), explicitTitle || title)
    .input("preview", sql.NVarChar(400), preview)
    .input("messageCount", sql.Int, messageCount)
    .input("messages", sql.NVarChar(sql.MAX), payload)
    .input("updatedAt", sql.DateTime2, now)
    .query(TSQL);

  const insertedId = r?.recordset?.[0]?.id || null;
  console.log(`[SQL] UPSERT chat for user=${userId} session=${sessionId} -> id=${insertedId}`);
  return insertedId;
}

async function insertFlagged({
  userId,
  sessionId,
  phase,
  originalPrompt,
  enhancedPrompt,
  reason,
  detail,
  requestId,
}) {
  if (!sqlPool) throw new Error("SQL pool not ready");
  const r = await sqlPool
    .request()
    .input("userId", sql.NVarChar(255), userId)
    .input("sessionId", sql.NVarChar(255), sessionId)
    .input("phase", sql.NVarChar(50), phase)
    .input("originalPrompt", sql.NVarChar(sql.MAX), originalPrompt || "")
    .input("enhancedPrompt", sql.NVarChar(sql.MAX), enhancedPrompt || null)
    .input("reason", sql.NVarChar(100), reason || null)
    .input("detail", sql.NVarChar(sql.MAX), detail ? JSON.stringify(detail) : null)
    .input("requestId", sql.NVarChar(100), requestId || null)
    .query(`
      INSERT INTO [dbo].[FlaggedMessages]
      ([userId],[sessionId],[phase],[originalPrompt],[enhancedPrompt],[reason],[detail],[requestId])
      OUTPUT inserted.id
      VALUES (@userId,@sessionId,@phase,@originalPrompt,@enhancedPrompt,@reason,@detail,@requestId)
    `);
  const id = r?.recordset?.[0]?.id || null;
  console.log(`[SQL] FLAGGED insert id=${id} user=${userId} session=${sessionId} phase=${phase}`);
  return id;
}

async function listChats(userId) {
  if (!sqlPool) throw new Error("SQL pool not ready");
  const r = await sqlPool
    .request()
    .input("userId", sql.NVarChar(255), userId)
    .query(`
      SELECT TOP 200 id, title, preview, messageCount, updatedAt
      FROM [dbo].[Chats]
      WHERE [userId] = @userId
      ORDER BY [updatedAt] DESC
    `);
  console.log(`[SQL] FETCH list for user=${userId} -> ${r.recordset.length} items`);
  return r.recordset;
}

async function getChat(userId, id) {
  if (!sqlPool) throw new Error("SQL pool not ready");
  const r = await sqlPool
    .request()
    .input("id", sql.UniqueIdentifier, id)
    .input("userId", sql.NVarChar(255), userId)
    .query(`
      SELECT TOP 1 id, userId, sessionId, title, preview, messageCount, messages, updatedAt, createdAt
      FROM [dbo].[Chats]
      WHERE [id] = @id AND [userId] = @userId
    `);
  console.log(`[SQL] FETCH chat id=${id} for user=${userId} -> ${r.recordset.length} rows`);
  return r.recordset[0] || null;
}

async function getChatByUserAndSession(userId, sessionId) {
  if (!sqlPool) throw new Error("SQL pool not ready");
  const r = await sqlPool
    .request()
    .input("userId", sql.NVarChar(255), userId)
    .input("sessionId", sql.NVarChar(255), sessionId)
    .query(`
      SELECT TOP 1 id, userId, sessionId, messages, updatedAt
      FROM [dbo].[Chats]
      WHERE [userId] = @userId AND [sessionId] = @sessionId
      ORDER BY [updatedAt] DESC
    `);
  return r.recordset[0] || null;
}

async function ensureSessionHydrated(userId, sessionId) {
  const k = keyFor(userId, sessionId);
  const existing = SESSIONS.get(k);
  if (existing && Array.isArray(existing.messages) && existing.messages.length > 0) {
    return;
  }
  try {
    const row = await getChatByUserAndSession(userId, sessionId);
    if (row) {
      const msgs = JSON.parse(row.messages || "[]");
      SESSIONS.set(k, { messages: msgs, updatedAt: Date.now() });
      console.log(
        `[SQL] HYDRATE memory from DB for user=${userId} session=${sessionId} (${msgs.length} msgs)`
      );
    } else {
      console.log(`[SQL] HYDRATE: no DB chat found for user=${userId} session=${sessionId}`);
    }
  } catch (e) {
    console.warn("[SQL] HYDRATE error:", e?.message || e);
  }
}

async function findOwnedChat({ userId, chatId, sessionId }) {
  if (!sqlPool) throw new Error("SQL pool not ready");
  if (chatId) {
    const r = await sqlPool
      .request()
      .input("id", sql.UniqueIdentifier, chatId)
      .input("userId", sql.NVarChar(255), userId)
      .query(`SELECT TOP 1 * FROM [dbo].[Chats] WHERE [id] = @id AND [userId] = @userId`);
    return r.recordset[0] || null;
  }
  if (sessionId) {
    const r = await sqlPool
      .request()
      .input("userId", sql.NVarChar(255), userId)
      .input("sessionId", sql.NVarChar(255), sessionId)
      .query(`
        SELECT TOP 1 * FROM [dbo].[Chats]
        WHERE [userId] = @userId AND [sessionId] = @sessionId
        ORDER BY [updatedAt] DESC
      `);
    return r.recordset[0] || null;
  }
  return null;
}

module.exports = {
  sql,
  sqlPool: () => sqlPool,
  ensureSchema,
  upsertChat,
  insertFlagged,
  listChats,
  getChat,
  getChatByUserAndSession,
  ensureSessionHydrated,
  findOwnedChat,
};
