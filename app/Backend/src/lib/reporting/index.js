const { ReportingError } = require("./errors");
const { createLockResource, withReportExecutionLock } = require("./locking");
const { fetchFlaggedIncidents, fetchKeywordIncidents, fetchLeadershipSummary, fetchTeacherSummary, fetchUsageSummaries, parseFlaggedDetail, severityMeetsThreshold } = require("./queries");
const { runDslDailyReport, runKeywordWatchReport, runLeadershipSummaryReport, runReportingRetention, runTeacherSummaryReport, runUsageDailyReport } = require("./runners");
const { getWatermark, updateWatermark } = require("./watermarks");

module.exports = {
  ReportingError,
  createLockResource,
  fetchFlaggedIncidents,
  fetchKeywordIncidents,
  fetchLeadershipSummary,
  fetchTeacherSummary,
  fetchUsageSummaries,
  getWatermark,
  parseFlaggedDetail,
  runDslDailyReport,
  runKeywordWatchReport,
  runLeadershipSummaryReport,
  runReportingRetention,
  runTeacherSummaryReport,
  runUsageDailyReport,
  severityMeetsThreshold,
  updateWatermark,
  withReportExecutionLock,
};
