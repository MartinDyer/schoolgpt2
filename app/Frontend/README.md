# SchoolSafeAI — Frontend (Developer Guide)

This document explains the frontend app in simple English for developers. It tells you what the app does, how the code is organized, how data flows, and how to run the project locally.

## What is this project?

This is the frontend for SchoolSafeAI. It is a small React + Vite app that shows a chat UI where a user can talk with an AI assistant. The frontend talks to a backend (Node or similar) to send and receive chat messages, save chat history, and share chats.

## High level flow (easy words)

- When the page opens, the app tries to restore the user session (MSAL / Microsoft sign-in) if available.
- The app keeps chat messages in session storage per session id. A session id is a random id created for each chat.
- When you type a message and send:
  - The user message is shown instantly in the UI.
  - The frontend sends the text to the backend (`/api/chat`).
  - When the backend replies, the assistant message appears in the UI.
  - The app saves the chat to the backend (`/api/chats/save`) in the background if the user is logged in.
- You can start a new chat (new session) which saves the current chat and clears the UI.
- If you are logged in, you can see saved chat history, load previous chats, and create a shareable link for a chat.

## Main files to know (frontend)

- `src/pages/Index.tsx` — Main page and largest logic. Handles messages, sessions, history, share link, and talking to backend.
- `src/components/ChatHeader.tsx` — Top bar. Shows login button, history, share, and logout.
- `src/components/ChatInput.tsx` — Input box at the bottom where user types messages.
- `src/components/ChatMessage.tsx` — Renders a single message bubble.
- `src/components/LoginDialog.tsx` — Login UI using MSAL.
- `src/components/ChatHistoryDialog.tsx` — UI to show saved chats from the backend and load them.
- `src/lib/auth/msal.ts` — MSAL helper functions (initialize, map accounts to user objects).
- `src/lib/utils.ts` — Small utility helpers used by the app.
- `src/hooks/use-toast.ts` — Simple toast notification hook used across the app.

There are many small UI components under `src/components/ui/` used for common UI building blocks (buttons, dialogs, inputs, etc.). You can open them when you need to change the look.

## Data and session handling (simple)

- Session id: the app uses a session id stored in `sessionStorage` under the key `sessionId`.
- Messages are saved per session under `chat:<sessionId>` in `sessionStorage`.
- When logged in, the app calls backend APIs to save chats into a database and to fetch saved chats.
- The app tries to save chats on important events (auto-after-reply, when starting a new chat, when sharing, and when importing a shared chat). It also attempts a beacon save on page hide.

## Backend API endpoints used by the frontend

The frontend expects a backend with these endpoints (pointed by `VITE_API_BASE`):

- `POST /api/chat` — send a user message, returns assistant reply.
- `POST /api/chats/save` — save current chat (userId, sessionId, messages).
- `GET /api/chats?userId=...` — list saved chats for a user.
- `GET /api/chats/:id?userId=...` — get a specific saved chat.
- `POST /api/chats/share-link` — create a share token for a chat.
- `GET /api/share/:token` — resolve a share token and return the chat data.
- `POST /api/chat/clear` — optional: clear server-side memory for a session.

The frontend will use `http://localhost:8080` by default if `VITE_API_BASE` is not set.

## Environment variables

- `VITE_API_BASE` — base URL for backend APIs (example: `http://localhost:8080`). Put this in a `.env` file if you want a different backend.

Example `.env` (Vite):

VITE_API_BASE=http://localhost:8080

Note: Vite requires `VITE_` prefix to expose env vars to the frontend.

## Auth (MSAL) notes

- The app uses MSAL for Microsoft sign-in. Helpers are in `src/lib/auth/msal.ts`.
- On load, the app calls `ensureMsalInitialized()` and reads the active account. If a user is present, the UI will show their name and allow saving/loading chats.
- If not logged in, the app will prompt the `LoginDialog` when user tries to save, share, or load history.

## How to run locally (simple steps)

1. Install dependencies (in project root):

   npm install

2. Create a `.env` file if you need to override the API base. Example:

   VITE_API_BASE=http://localhost:8080

3. Start the dev server:

   npm run dev

4. Open the app in your browser (usually at `http://localhost:5173`).

If your backend runs at a different port, set `VITE_API_BASE` appropriately.

## Common development tasks (quick)

- Change UI: edit files under `src/components/` and `src/components/ui/`.
- Change chat logic: `src/pages/Index.tsx`.
- Add a new backend call: import `API_BASE` and use `fetch()` similar to existing calls.
- Debugging: open the browser console. The app writes helpful logs (prefixes like `[AUTH]`, `[HISTORY]`, `[FRONTEND]`).

## Tips and gotchas (plain language)

- Session storage is used for quick local saves. This means messages persist while your browser tab is open or until you start a new session.
- The app requires login for persistent history. If you test without auth, you can still chat but history won't be saved to backend.
- The share flow imports a chat and immediately saves it on the backend under a new session id so future messages use that session id.
- The app shows a browser confirm when you try to close the page and you have unsaved messages while logged in; this prevents accidental loss.

## Where to look first when you join the project

1. `src/pages/Index.tsx` — main logic and best place to understand end-to-end flow.
2. `src/lib/auth/msal.ts` — authentication wiring.
3. `src/components/ChatInput.tsx` and `src/components/ChatMessage.tsx` — send and render messages.

## Docker & Deployment

This project is fully dockerized for easy deployment. You can deploy to Railway, VPS, or any Docker-compatible platform.

### Quick Docker Commands

```bash
# Start the application in Docker
npm run docker:up

# Stop the application
npm run docker:down

# View logs
npm run docker:logs

# Rebuild and restart
npm run docker:rebuild
```

### Deploy to Production

For detailed deployment instructions to Railway, VPS (DigitalOcean, AWS, Linode, etc.), and SSL setup, see:

**📖 [DEPLOYMENT.md](./DEPLOYMENT.md)** - Complete deployment guide

**📖 [DOCKER.md](./DOCKER.md)** - Docker configuration details

The app runs in a production-optimized Nginx container (~30MB) with:
- Multi-stage Docker build
- Automatic gzip compression
- Security headers configured
- Health checks enabled
- Static asset caching

