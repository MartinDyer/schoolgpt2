function parseCsvList(value) {
  return String(value || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function getSettings() {
  return {
    schoolName: process.env.SCHOOL_NAME || "SchoolGPT",
    dslEmail: process.env.DSL_EMAIL || "",
    summaryEmails: parseCsvList(process.env.SUMMARY_EMAILS),
    leadershipEmails: parseCsvList(process.env.LEADERSHIP_EMAILS),
    teacherSummaryEmails: parseCsvList(process.env.TEACHER_SUMMARY_EMAILS),
    enableCsvExport: String(process.env.ENABLE_CSV_EXPORT || "true").toLowerCase() === "true",
    csvExportThreshold: Number(process.env.CSV_EXPORT_THRESHOLD || "10"),
    reportingInitialWatermark: new Date(process.env.REPORTING_INITIAL_WATERMARK || "2026-01-01T00:00:00Z"),
    keywordWatchTerms: parseCsvList(process.env.KEYWORD_WATCH_TERMS),
    dslMinSeverity: process.env.DSL_MIN_SEVERITY || "medium",
    reportingAuditRetentionDays: Number(process.env.REPORTING_AUDIT_RETENTION_DAYS || "90"),
  };
}

module.exports = {
  getSettings,
  parseCsvList,
};
