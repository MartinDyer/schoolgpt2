const test = require("node:test");
const assert = require("node:assert/strict");

process.env.NO_SQL_BOOTSTRAP = "1";

const { ReportingError } = require("./errors");
const { createReportingRunners } = require("./runners");

function createBaseDeps(overrides = {}) {
  const updateCalls = [];

  return {
    updateCalls,
    deps: {
      sql: { Int: "Int" },
      sqlPool: () => ({
        request: () => ({
          input() {
            return this;
          },
          async query() {
            return { rowsAffected: [0] };
          },
        }),
      }),
      recordAudit: async () => {},
      getSettings: () => ({
        schoolName: "Example School",
        dslEmail: "dsl@example.com",
        summaryEmails: ["summary@example.com"],
        leadershipEmails: ["leadership@example.com"],
        teacherSummaryEmails: ["teachers@example.com"],
        enableCsvExport: false,
        csvExportThreshold: 10,
        reportingInitialWatermark: new Date("2026-01-01T00:00:00Z"),
        keywordWatchTerms: ["term"],
        dslMinSeverity: "medium",
        reportingAuditRetentionDays: 90,
      }),
      sendEmail: async () => {},
      fetchFlaggedIncidents: async () => [],
      fetchKeywordIncidents: async () => [],
      fetchLeadershipSummary: async () => ({
        generatedAt: "2026-04-14T00:00:00.000Z",
        totalFlaggedIncidents: 3,
        highSeverityIncidents: 1,
        uniqueImpactedUsers: 2,
        categoryBreakdown: {},
        severityBreakdown: {},
        sourceHighWatermark: "2026-04-12T15:30:00.000Z",
      }),
      fetchTeacherSummary: async () => ({
        generatedAt: "2026-04-14T00:00:00.000Z",
        blockedSearches: 4,
        mediumOrHigherIncidents: 2,
        recurringRiskPatterns: ["Repeated concern in self_harm (2 occurrences)"],
        referralRequired: true,
        sourceHighWatermark: "2026-04-13T09:45:00.000Z",
      }),
      fetchUsageSummaries: async () => ({
        summaries: [{ usageDate: "2026-04-14", uniqueUsers: 3, uniqueSessions: 4, totalMessages: 12 }],
        sourceHighWatermark: new Date("2026-04-14T18:00:00.000Z"),
      }),
      createCsvAttachment: () => ({ name: "x.csv" }),
      renderDslIncidentEmail: () => "dsl",
      renderKeywordWatchEmail: () => "keyword",
      renderLeadershipSummaryEmail: () => "leadership",
      renderTeacherSummaryEmail: () => "teacher",
      renderUsageSummaryEmail: () => "usage",
      getWatermark: async () => new Date("2026-04-10T00:00:00.000Z"),
      withReportExecutionLock: async (_report, _reportName, operation) => operation(),
      updateWatermark: async (reportName, value) => {
        updateCalls.push([reportName, value]);
      },
      ...overrides,
    },
  };
}

test("usage report advances watermark with source high watermark", async () => {
  const { deps, updateCalls } = createBaseDeps();
  const runners = createReportingRunners(deps);

  const result = await runners.runUsageDailyReport();

  assert.deepEqual(result, { count: 1, sent: true });
  assert.equal(updateCalls.length, 1);
  assert.equal(updateCalls[0][0], "usage_daily_report");
  assert.equal(updateCalls[0][1].toISOString(), "2026-04-14T18:00:00.000Z");
});

test("leadership report advances watermark with source incident watermark", async () => {
  const { deps, updateCalls } = createBaseDeps();
  const runners = createReportingRunners(deps);

  const result = await runners.runLeadershipSummaryReport();

  assert.deepEqual(result, { count: 3, sent: true });
  assert.equal(updateCalls.length, 1);
  assert.equal(updateCalls[0][0], "leadership_summary_report");
  assert.equal(updateCalls[0][1].toISOString(), "2026-04-12T15:30:00.000Z");
});

test("teacher report advances watermark with source incident watermark", async () => {
  const { deps, updateCalls } = createBaseDeps();
  const runners = createReportingRunners(deps);

  const result = await runners.runTeacherSummaryReport();

  assert.deepEqual(result, { count: 4, sent: true });
  assert.equal(updateCalls.length, 1);
  assert.equal(updateCalls[0][0], "teacher_summary_report");
  assert.equal(updateCalls[0][1].toISOString(), "2026-04-13T09:45:00.000Z");
});

test("runner wraps report execution in a per-report lock", async () => {
  const observed = [];
  const { deps } = createBaseDeps({
    withReportExecutionLock: async (report, reportName, operation) => {
      observed.push([report, reportName, "acquired"]);
      const result = await operation();
      observed.push([report, reportName, "released"]);
      return result;
    },
  });
  const runners = createReportingRunners(deps);

  const result = await runners.runUsageDailyReport();

  assert.deepEqual(result, { count: 1, sent: true });
  assert.deepEqual(observed, [
    ["usage-daily", "usage_daily_report", "acquired"],
    ["usage-daily", "usage_daily_report", "released"],
  ]);
});

test("runner stops immediately when the report lock is already held", async () => {
  let called = false;
  const { deps, updateCalls } = createBaseDeps({
    getSettings: () => {
      called = true;
      return createBaseDeps().deps.getSettings();
    },
    withReportExecutionLock: async (_report, _reportName, _operation) => {
      throw new ReportingError({
        code: "reporting_execution_locked",
        message: "Report 'usage-daily' is already running",
        report: "usage-daily",
        retryable: true,
        status: 409,
      });
    },
  });
  const runners = createReportingRunners(deps);

  await assert.rejects(() => runners.runUsageDailyReport(), (error) => {
    assert.equal(error.code, "reporting_execution_locked");
    assert.equal(error.report, "usage-daily");
    assert.equal(error.retryable, true);
    assert.equal(error.status, 409);
    return true;
  });

  assert.equal(called, false);
  assert.equal(updateCalls.length, 0);
});
