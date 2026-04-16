const express = require("express");
const {
  runDslDailyReport,
  runUsageDailyReport,
  runKeywordWatchReport,
  runLeadershipSummaryReport,
  runTeacherSummaryReport,
  runReportingRetention,
} = require("../lib/reporting");

const router = express.Router();

router.use((req, res, next) => {
  const expected = process.env.REPORTING_API_KEY || "";
  const provided = req.get("x-reporting-key") || "";
  if (!expected || provided !== expected) {
    return res.status(401).json({ ok: false, error: "unauthorized" });
  }
  next();
});

router.get("/reporting/health", (_req, res) => {
  return res.json({ ok: true });
});

router.post("/reporting/run/dsl-daily", async (_req, res) => {
  const result = await runDslDailyReport();
  return res.json({ ok: true, ...result });
});

router.post("/reporting/run/usage-daily", async (_req, res) => {
  const result = await runUsageDailyReport();
  return res.json({ ok: true, ...result });
});

router.post("/reporting/run/keyword-watch", async (_req, res) => {
  const result = await runKeywordWatchReport();
  return res.json({ ok: true, ...result });
});

router.post("/reporting/run/leadership-summary", async (_req, res) => {
  const result = await runLeadershipSummaryReport();
  return res.json({ ok: true, ...result });
});

router.post("/reporting/run/teacher-summary", async (_req, res) => {
  const result = await runTeacherSummaryReport();
  return res.json({ ok: true, ...result });
});

router.post("/reporting/run/retention", async (_req, res) => {
  const result = await runReportingRetention();
  return res.json({ ok: true, ...result });
});

module.exports = router;
