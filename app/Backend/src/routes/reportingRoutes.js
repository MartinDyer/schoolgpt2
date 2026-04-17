const express = require("express");
const {
  runDslDailyReport,
  runUsageDailyReport,
  runKeywordWatchReport,
  runLeadershipSummaryReport,
  runTeacherSummaryReport,
  runReportingRetention,
} = require("../lib/reporting");
const { ReportingError, createReportingErrorResponse } = require("../lib/reporting/errors");

function createReportingRouter(deps = {}) {
  const router = express.Router();
  const reporting = {
    runDslDailyReport,
    runUsageDailyReport,
    runKeywordWatchReport,
    runLeadershipSummaryReport,
    runTeacherSummaryReport,
    runReportingRetention,
    ...deps,
  };

  router.use((req, res, next) => {
    const expected = process.env.REPORTING_API_KEY || "";
    const provided = req.get("x-reporting-key") || "";

    if (!expected || provided !== expected) {
      const { status, body } = createReportingErrorResponse(
        new ReportingError({
          code: "reporting_unauthorized",
          message: "Unauthorized reporting request",
          report: "unknown",
          retryable: false,
          status: 401,
        }),
        { report: "unknown", requestId: req.requestId || "" }
      );
      return res.status(status).json(body);
    }

    return next();
  });

  router.get("/reporting/health", (_req, res) => {
    return res.json({ ok: true });
  });

  router.post("/reporting/run/dsl-daily", createRunHandler("dsl-daily", reporting.runDslDailyReport));
  router.post("/reporting/run/usage-daily", createRunHandler("usage-daily", reporting.runUsageDailyReport));
  router.post("/reporting/run/keyword-watch", createRunHandler("keyword-watch", reporting.runKeywordWatchReport));
  router.post("/reporting/run/leadership-summary", createRunHandler("leadership-summary", reporting.runLeadershipSummaryReport));
  router.post("/reporting/run/teacher-summary", createRunHandler("teacher-summary", reporting.runTeacherSummaryReport));
  router.post("/reporting/run/retention", createRunHandler("retention", reporting.runReportingRetention));

  return router;
}

function createRunHandler(report, runner) {
  return async function runReportingHandler(req, res) {
    try {
      const result = await runner();
      return res.json({ ok: true, report, ...result });
    } catch (error) {
      const { status, body } = createReportingErrorResponse(error, {
        report,
        requestId: req.requestId || "",
      });
      return res.status(status).json(body);
    }
  };
}

const router = createReportingRouter();

module.exports = router;
module.exports.createReportingRouter = createReportingRouter;
