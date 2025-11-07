# SchoolSafeAI — Backend Overview

This document explains the backend code and runtime flow for SchoolSafeAI after refactoring the original monolithic server into routers and small helper modules. It lists the key files, request flow, policy/error handling, environment variables, and quick local run instructions.

## Repository structure (relevant files)

- `server.js` — Express bootstrap that mounts routers from `src/routes` and exposes `/health`.
- `src/routes/chatRoutes.js` — main chat router implementing `/api/chat`, `/api/chat/clear`, `/api/chats/save`, `/api/chats` (GET list), and `/api/chats/:id` (GET single).
- `src/routes/shareRoutes.js` — share-link routes: `POST /api/chats/share-link` and `GET /api/share/:token`.
- `src/lib/prompt.js` — exports `enhancerSystemPrompt` (the system instruction used for prompt enhancement).
- `src/lib/session.js` — in-memory session store and context builder.
- `src/lib/openai.js` — OpenAI/Azure helpers and policy/filter helpers.
- `src/lib/db.js` — Azure SQL helpers (schema, chats, flagged messages, share links, hydration).

## High-level request flow

1. Requests hit `server.js` and are routed to the mounted routers under `/api`.
2. `chatRoutes` runs the chat lifecycle: optional enhancement, session hydration, context assembly, model call, and reply handling.
3. Prompt enhancement is delegated to `src/lib/prompt.js` (if an API key is available).
4. Session history is stored in-memory (bounded) and persisted via `src/lib/db.js` when saved.
5. Model calls and content/policy checks use helpers in `src/lib/openai.js`.

## `/api/chat` (implemented in `src/routes/chatRoutes.js`)

**Flow:**
1. Validate inputs (`message`, `userId`, `sessionId`) and return a friendly message for empty prompts.
2. Call the enhancer using `enhancerSystemPrompt` from `src/lib/prompt.js` with the user's prompt (if API key is available). If the enhancer response is filtered by `choiceFiltered`, record it via `insertFlagged` and return a refusal using the helper function `replyBlockedAndRecord`.
3. Ensure session is hydrated via `ensureSessionHydrated(userId, sessionId)` to load any saved chat history from the database.
4. Build context messages with `buildContextMessages(history, userPrompt, enhancedPrompt)` which includes: system prompt + session history + two user messages (original and enhanced prompts).
5. Call the chat completion endpoint (or use demo fallback if no API key). If the model response indicates policy filtering via `choiceFiltered`, or if an axios error is detected by `isContentFilterErr`, record it with `insertFlagged` and return a safe refusal to the client.
6. On success, append both user prompts (original and enhanced) and the assistant reply to the in-memory session and return the assistant's reply along with usage/latency metadata.

## Important modules

- `src/lib/session.js` — Exports `SESSIONS` (Map), `keyFor`, `getSession`, `addMsg`, `trimSession`, `buildContextMessages`, and constants `MAX_MESSAGES`, `MAX_CHARS`, `SYSTEM_PROMPT`.
- `src/lib/prompt.js` — Exports `enhancerSystemPrompt` (the system instruction string used to rewrite user prompts during enhancement).
- `src/lib/openai.js` — Exports `axios`, `chatUrl`, `headers`, `refusalText`, and helper functions `choiceFiltered` & `isContentFilterErr`.
- `src/lib/db.js` — DB connection and helpers: `ensureSchema`, `upsertChat`, `listChats`, `getChat`, `getChatByUserAndSession`, `insertFlagged`, `ensureSessionHydrated`, `findOwnedChat`, plus exports `sql` and `sqlPool` function.

## Data shapes

- Session message: { role: 'user'|'assistant'|'system', content: string }
- In-memory session: { messages: Array<message>, updatedAt: number }
- Chat DB row: { id, userId, sessionId, title, preview, messageCount, messages, createdAt, updatedAt }

## Policy & error handling

- If `choiceFiltered` flags a model/enhancer response or `isContentFilterErr` recognizes a policy error, the server uses the helper function `replyBlockedAndRecord` which:
  - logs the event with phase and details,
  - conditionally appends user prompts to the in-memory session (original and enhanced if available),
  - adds the canned `refusalText` to the session,
  - inserts a `FlaggedMessages` row for auditing (done before calling `replyBlockedAndRecord`),
  - returns a 200 JSON response with `blocked: true`, `reason: 'content_filter'`, and the `refusalText` as the reply.

This preserves an audit trail and ensures the client receives a safe refusal instead of disallowed content.

## Environment variables

- `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_DEPLOYMENT`, `AZURE_OPENAI_API_VERSION` — used for constructing Azure chat endpoints.
- `AZURE_OPENAI_API_KEY` — enables enhancement and model calls; when absent the server falls back to demo replies.
- `AZURE_SQL_USER`, `AZURE_SQL_PASS`, `AZURE_SQL_SERVER`, `AZURE_SQL_DB` — Azure SQL connection details.
- `PORT` — HTTP port (defaults to 8080).

## Run locally (quick)

1. Install dependencies:

```
npm install
```

2. Create a `.env` at the repo root. Minimal example to run without OpenAI/DB:

```
PORT=8080
# leave AZURE_OPENAI_API_KEY unset to exercise demo fallback replies
```

3. Start the server:

```
node server.js
```

4. Test `POST /api/chat` with JSON: `{ "userId":"user-123","sessionId":"default","message":"Explain photosynthesis to a 12-year-old" }`.

If no API key is configured, the server returns a demo reply: "I'm here to help you learn! (demo reply)".

## Troubleshooting

- "SQL pool not ready": ensure Azure SQL env vars and network connectivity are correct. DB helper logs connection attempts at boot.
- Model call failures/timeouts: verify `AZURE_OPENAI_ENDPOINT`, deployment name, and API key; check server logs for axios error details.

---

For implementation details, see `src/routes/chatRoutes.js`, `src/lib/prompt.js`, and `src/lib/openai.js`.
  - Send request to the chat completions endpoint (`openai.js` wraps axios config).
  - If model response indicates content filtering or policy issues, record the flagged item to DB (`insertFlagged`) and return a safe refusal to the user, also appending the prompts and refusal into in-memory session.
  - On success, append the original/enhanced prompts and assistant reply to the in-memory session and return the reply.

## `src/lib/session.js` — in-memory conversation and helpers

Purpose: keep short-term conversation memory in process. This is not persistent storage; the DB is used for saving full chat transcripts.

Key exports:

- `SESSIONS` — a Map keyed by `userId::sessionId`, each value is an object: `{ messages: [], updatedAt }`.
- `MAX_MESSAGES` — constant set to 100 (max number of messages kept in memory).
- `MAX_CHARS` — constant set to 35000 (max total character length of messages).
- `SYSTEM_PROMPT` — the system instruction sent to the model: _"You are SchoolSafeAI, a helpful, safe assistant for a K-12 school. Be concise, factual, and age-appropriate. If a request is unsafe or not allowed, explain why and offer safer alternatives."_
- `keyFor(userId, sessionId)` — convenience to build consistent keys (defaults to `anonymous::default` when missing).
- `getSession(key)` — create-if-missing and return the session object.
- `addMsg(key, role, content)` — push a new message into session with a role (`user` or `assistant`) and content, update timestamp, then call `trimSession`.
- `trimSession(session)` — keeps in-memory sessions bounded by two limits:
  - `MAX_MESSAGES` (100 messages) — if exceeded keep only the last 100 messages.
  - `MAX_CHARS` (35,000 chars) — starting from the most recent message count backwards until the cumulative char length is below this threshold.
- `buildContextMessages(sessionMsgs, userPrompt, enhancedPrompt)` — returns the array of messages to send to the model: system prompt, session messages, then two user messages (original and enhanced).

Why this design? Keeping a bounded in-memory history reduces request sizes, keeps relevant recent messages, and prevents sending huge histories to the LLM.

## `src/lib/openai.js` — Azure OpenAI config and safety helpers

This file centralizes OpenAI/Azure OpenAI configuration and some small helpers used by the routes and prompt helper.

Important exports:

- `axios` — the axios library instance.
- `endpointBase`, `deployment`, `apiVersion` — build the Azure chat completions URL from environment variables.
- `chatUrl` — the full HTTP endpoint used for chat completions.
- `headers` — includes `Content-Type` and the `api-key` header which comes from `AZURE_OPENAI_API_KEY`.
- `refusalText` — canned reply: _"I'm unable to assist you with that request due to safety guidelines. If you'd like, I can help with safer, educational alternatives."_

Helpers:

- `isContentFilterErr(err)` — inspects an axios error response and detects whether the error was due to the Azure content filter / Responsible AI policy by checking error codes, innererror codes, and message text. Returns boolean.
- `choiceFiltered(choice)` — inspects a single model choice (response) and checks for indicators that it was filtered due to hate, self_harm, sexual content, violence, or if the finish reason is `content_filter`. Returns boolean.

Why this design? Centralizing filter checks and URL/headers helps the rest of the code handle policy errors consistently.

## `src/lib/db.js` — Azure SQL helpers and schema

Purpose: Manage persistent chat storage and flagged messages for auditing.

Key behaviors:

- Connects to Azure SQL using `mssql` and `sql.connect(sqlConfig)`. The connection attempts at module load time (see `bootSql` IIFE).
- `ensureSchema()` — runs T-SQL to create three tables if they don't exist:
  - `Chats` — stores full conversation JSON in `messages` (NVARCHAR(MAX)), plus id (UNIQUEIDENTIFIER), userId, sessionId, title, preview, messageCount, createdAt, updatedAt. Has indexes on userId/updatedAt.
  - `FlaggedMessages` — stores flagged prompt requests with id (UNIQUEIDENTIFIER), userId, sessionId, phase (ENHANCE | ANSWER), originalPrompt, enhancedPrompt, reason, detail, requestId, createdAt. Has indexes on createdAt and userId/createdAt.
  - `ShareLinks` — stores tokens for sharing chats publicly with id (UNIQUEIDENTIFIER), token (unique), chatId, ownerUserId, createdAt. Has unique index on token and index on chatId.
- `deriveTitleAndPreview(messages)` — internal helper to build a title (first user message, max 100 chars) and preview text (last two messages or first user message, max 200 chars) for the chat when saving.
- `upsertChat({ userId, sessionId, messages, explicitTitle })` — inserts a new row or updates an existing chat for the same user+session using T-SQL MERGE logic. Returns the chat id.
- `insertFlagged({ userId, sessionId, phase, originalPrompt, enhancedPrompt, reason, detail, requestId })` — inserts a flagged prompt record for later review. Returns the flagged message id.
- `listChats(userId)` — fetches top 200 chats for a user ordered by updatedAt DESC. Returns array with id, title, preview, messageCount, updatedAt.
- `getChat(userId, id)` — fetches a single chat by id for the given user. Returns full chat object or null.
- `getChatByUserAndSession(userId, sessionId)` — fetches the most recent chat for a user+session combination.
- `ensureSessionHydrated(userId, sessionId)` — if in-memory session is empty, try to fetch the most recent `Chats` row for the user/session and populate `SESSIONS` with the saved messages. This is used by `chatRoutes` before building the context.
- `findOwnedChat({ userId, chatId, sessionId })` — finds a chat owned by the user, searching by chatId (if provided) or sessionId (fallback). Used for share-link creation.

Exports: `sql`, `sqlPool` (function that returns the pool), and all the helper functions listed above.

Notes about DB startup and errors:

- The code logs a connection error if Azure SQL is not reachable at boot. Many helper functions will throw "SQL pool not ready" if called before the connection succeeds. That is expected if environment variables are missing or the DB is down.

## `src/lib/prompt.js` — prompt enhancement system prompt

This module exports the system instruction used for prompt enhancement.

Key export:

- `enhancerSystemPrompt` — a string containing the instruction: _"You are a strict prompt enhancer for a school-safe chatbot. Rewrite the user's prompt to be clear, concise, and age-appropriate (10–18). Preserve intent, remove PII/unsafe parts, and add brief missing context if obvious. Output ONLY the enhanced prompt text."_

The actual enhancement logic (calling the chat endpoint with this system prompt) is implemented directly in `src/routes/chatRoutes.js` in the `/api/chat` route handler.

  ## Environment variables used

  - AZURE_OPENAI_ENDPOINT — base URL for the Azure OpenAI resource (example: `https://my-openai-resource.openai.azure.com`).
  - AZURE_OPENAI_DEPLOYMENT — the deployment name for the chat model on Azure.
  - AZURE_OPENAI_API_VERSION — optional, defaults to `2025-01-01-preview` in the code.
  - AZURE_OPENAI_API_KEY — the API key for Azure OpenAI. When missing, the server will skip enhancement and the model call; it still runs but uses demo/fallback replies.
  - AZURE_SQL_USER, AZURE_SQL_PASS, AZURE_SQL_SERVER, AZURE_SQL_DB — SQL connection info for Azure SQL.
  - PORT — HTTP port the Express app listens on (defaults to 8080).

  ## Data shapes

  - Session message: { role: 'user'|'assistant'|'system', content: string }
  - In-memory session: { messages: Array<message>, updatedAt: number }
  - Chat row in DB: { id, userId, sessionId, title, preview, messageCount, messages, createdAt, updatedAt }

## Additional chat routes

- `POST /api/chats/save` — saves a chat to the database. Requires `userId`, `sessionId`, `messages` (array), and optional `explicitTitle`. Calls `upsertChat` and returns `{ ok: true, id }`.
- `GET /api/chats` — lists all chats for a user. Requires `userId` query param. Returns `{ ok: true, items }` with top 200 chats.
- `GET /api/chats/:id` — fetches a single chat by id. Requires `userId` query param. Also hydrates the in-memory session with the chat's messages. Returns `{ ok: true, chat }` or 404.
- `POST /api/chat/clear` — clears the in-memory session for a user+sessionId. Returns `{ ok: true, cleared: <key> }`.

## Share link routes (in `src/routes/shareRoutes.js`)

- `POST /api/chats/share-link` — creates a shareable link for a chat. Requires `userId` and either `chatId` or `sessionId`. Uses `findOwnedChat` to verify ownership, generates a random token, inserts into `ShareLinks` table, and returns `{ ok: true, token }`.
- `GET /api/share/:token` — retrieves a shared chat by token. Returns `{ ok: true, ownerUserId, chat }` with full chat details, or 404 if token is invalid.

  ## How to run locally (quick)

  1. Ensure Node.js is installed (the repo appears to be Node/Express).
  2. Create a `.env` file in the repository root and populate values you have. Minimal to test without OpenAI/DB:

  ```
  PORT=8080
  # Do not set AZURE_OPENAI_API_KEY if you want to exercise fallback behavior
  ```

  3. Install dependencies (from repository root):

  ```
  npm install
  ```

  4. Start the server:

  ```
  node server.js
  ```

  5. Test the chat endpoint with curl, Postman, or a simple fetch. Example body for `POST /api/chat`:

  ```
  {
    "userId": "user-123",
    "sessionId": "default",
    "message": "What's a simple explanation of photosynthesis for a 12-year-old?"
  }
  ```

  If no Azure OpenAI key is configured, the server returns a demo reply: "I'm here to help you learn! (demo reply)".

  ## Common troubleshooting

  - "SQL pool not ready" errors: check SQL env vars and network access to the DB. The code logs connection errors at boot.
  - Model calls timing out or failing: verify `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_DEPLOYMENT`, and `AZURE_OPENAI_API_KEY` are correct. Also watch the server logs for detailed axios error objects.

## Quick example: what happens when `/api/chat` is called

1. Request arrives with message "How do I make a bomb?" (unsafe)
2. Enhancement step calls the model with `enhancerSystemPrompt` and the user's prompt. If `choiceFiltered` detects the enhancer response is blocked, it's stored in `FlaggedMessages` with phase='ENHANCE' and the user receives `refusalText` via `replyBlockedAndRecord`.
3. If enhancement succeeds, the session is hydrated from DB (if needed), context is built, and the model is called with both original and enhanced prompts.
4. If the model response is flagged by `choiceFiltered` or an axios error is detected by `isContentFilterErr`, it's stored in `FlaggedMessages` with phase='ANSWER' and the user receives `refusalText`.
5. If allowed, the original prompt, enhanced prompt, and assistant reply are appended to in-memory session and returned to the client with usage/latency metadata.
 

