console.log("------------------------------------------------------------------");
console.log(`[BOOT] STARTING NODE PROCESS`);
console.log(`[BOOT] Time: ${new Date().toISOString()}`);

process.on("uncaughtException", (err) => {
  console.error("[BOOT] UNCAUGHT EXCEPTION:", err);
  process.exit(1);
});

process.on("unhandledRejection", (reason, promise) => {
  console.error("[BOOT] UNHANDLED REJECTION:", reason);
});

console.log("------------------------------------------------------------------");

// /server.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { randomUUID } = require("crypto");

const path = require("path");

// Routers
const chatRoutes = require("./src/routes/chatRoutes");
const shareRoutes = require("./src/routes/shareRoutes");

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json({ limit: "2mb" }));

// X-Request-Id (kept exactly as before)
app.use((req, res, next) => {
  req.requestId = randomUUID();
  res.setHeader("X-Request-Id", req.requestId);
  next();
});

// Mount routers under /api  (route paths inside routers already start with /chat(s) and /share)
app.use("/api", chatRoutes);
app.use("/api", shareRoutes);

// Serve static files from the 'public' directory
app.use(express.static(path.join(__dirname, 'public')));

// health
app.get("/health", (_, res) => res.json({ status: "ok" }));

// Catch-all route to serve the React app
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`[BOOT] API listening on http://localhost:${PORT}`);
});
