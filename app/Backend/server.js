// /server.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { randomUUID } = require("crypto");

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

// health
app.get("/health", (_, res) => res.json({ status: "ok" }));

app.listen(PORT, () => {
  console.log(`[BOOT] API listening on http://localhost:${PORT}`);
});
