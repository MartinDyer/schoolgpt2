const { randomUUID } = require("crypto");
const { EmailClient } = require("@azure/communication-email");
const { sql, sqlPool } = require("./db");

const severityOrder = { low: 1, medium: 2, high: 3, critical: 4 };

function severityMeetsThreshold(severity, minSeverity) {
  return (severityOrder[(severity || "medium").toLowerCase()] || 2) >= (severityOrder[(minSeverity || "medium").toLowerCase()] || 2);
}

async function ensureReportingTables() {
  await sqlPool()
    .request()
    .batch(`
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReportingWatermarks]') AND type in (N'U'))
BEGIN
  CREATE TABLE [dbo].[ReportingWatermarks] (
    [ReportName] NVARCHAR(100) NOT NULL PRIMARY KEY,
    [LastProcessedAt] DATETIME2 NOT NULL,
    [UpdatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReportingAuditLog]') AND type in (N'U'))
BEGIN
  CREATE TABLE [dbo].[ReportingAuditLog] (
    [AuditId] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    [ReportName] NVARCHAR(100) NOT NULL,
    [EventType] NVARCHAR(100) NOT NULL,
    [EventDescription] NVARCHAR(MAX) NOT NULL,
    [Severity] NVARCHAR(20) NOT NULL DEFAULT 'Info',
    [ReasonCode] NVARCHAR(100) NULL,
    [Recipients] NVARCHAR(MAX) NULL,
    [AdditionalData] NVARCHAR(MAX) NULL,
    [Timestamp] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    [Source] NVARCHAR(100) NOT NULL DEFAULT 'SchoolGPT.Reporting'
  );
END;
`);
}

async function getWatermark(reportName, initialValue) {
  await ensureReportingTables();
  const request = sqlPool().request();
  request.input("reportName", sql.NVarChar(100), reportName);
  const existing = await request.query("SELECT LastProcessedAt FROM dbo.ReportingWatermarks WHERE ReportName = @reportName");
  if (existing.recordset[0]?.LastProcessedAt) {
    return existing.recordset[0].LastProcessedAt;
  }
  await sqlPool()
    .request()
    .input("reportName", sql.NVarChar(100), reportName)
    .input("lastProcessedAt", sql.DateTime2, initialValue)
    .query("INSERT INTO dbo.ReportingWatermarks (ReportName, LastProcessedAt) VALUES (@reportName, @lastProcessedAt)");
  return initialValue;
}

async function updateWatermark(reportName, newValue) {
  await ensureReportingTables();
  await sqlPool()
    .request()
    .input("reportName", sql.NVarChar(100), reportName)
    .input("lastProcessedAt", sql.DateTime2, newValue)
    .query(`
      MERGE dbo.ReportingWatermarks AS target
      USING (SELECT @reportName AS ReportName, @lastProcessedAt AS LastProcessedAt) AS source
      ON target.ReportName = source.ReportName
      WHEN MATCHED THEN UPDATE SET LastProcessedAt = source.LastProcessedAt, UpdatedAt = SYSUTCDATETIME()
      WHEN NOT MATCHED THEN INSERT (ReportName, LastProcessedAt) VALUES (source.ReportName, source.LastProcessedAt);
    `);
}

async function recordAudit(reportName, eventType, description, options = {}) {
  await ensureReportingTables();
  await sqlPool()
    .request()
    .input("auditId", sql.UniqueIdentifier, randomUUID())
    .input("reportName", sql.NVarChar(100), reportName)
    .input("eventType", sql.NVarChar(100), eventType)
    .input("eventDescription", sql.NVarChar(sql.MAX), description)
    .input("severity", sql.NVarChar(20), options.severity || "Info")
    .input("reasonCode", sql.NVarChar(100), options.reasonCode || null)
    .input("recipients", sql.NVarChar(sql.MAX), (options.recipients || []).join(","))
    .input("additionalData", sql.NVarChar(sql.MAX), JSON.stringify(options.additionalData || {}))
    .query(`
      INSERT INTO dbo.ReportingAuditLog (AuditId, ReportName, EventType, EventDescription, Severity, ReasonCode, Recipients, AdditionalData, Timestamp, Source)
      VALUES (@auditId, @reportName, @eventType, @eventDescription, @severity, @reasonCode, @recipients, @additionalData, SYSUTCDATETIME(), 'SchoolGPT.Reporting')
    `);
}

function parseFlaggedDetail(detailJson, reason) {
  if (!detailJson) return { severity: "medium", filterType: reason || "content_filter", details: null };
  try {
    const parsed = JSON.parse(detailJson);
    if (parsed && typeof parsed === "object") {
      for (const [category, payload] of Object.entries(parsed)) {
        if (payload && typeof payload === "object" && payload.filtered) {
          return { severity: payload.severity || "medium", filterType: category, details: detailJson };
        }
      }
    }
  } catch {
    return { severity: "medium", filterType: reason || "content_filter", details: detailJson };
  }
  return { severity: "medium", filterType: reason || "content_filter", details: detailJson };
}

async function fetchFlaggedIncidents(sinceUtc, minSeverity = "medium") {
  const result = await sqlPool()
    .request()
    .input("sinceUtc", sql.DateTime2, sinceUtc)
    .query(`
      SELECT TOP 500 id, userId, sessionId, phase, originalPrompt, enhancedPrompt, reason, detail, createdAt
      FROM dbo.FlaggedMessages
      WHERE createdAt > @sinceUtc
      ORDER BY createdAt ASC
    `);

  return result.recordset
    .map((row) => {
      const parsed = parseFlaggedDetail(row.detail, row.reason);
      return {
        incidentId: String(row.id),
        userId: row.userId,
        displayName: row.userId || "Unknown User",
        sessionId: row.sessionId,
        phase: row.phase,
        filterType: parsed.filterType,
        severity: parsed.severity,
        actionTaken: row.phase || "Blocked",
        userMessage: row.originalPrompt || row.enhancedPrompt || "",
        timestamp: row.createdAt,
        details: parsed.details,
      };
    })
    .filter((item) => severityMeetsThreshold(item.severity, minSeverity));
}

async function fetchUsageSummaries(sinceUtc) {
  const result = await sqlPool()
    .request()
    .input("sinceUtc", sql.DateTime2, sinceUtc)
    .query(`
      SELECT CAST(updatedAt AS DATE) AS usageDate,
             COUNT(DISTINCT userId) AS uniqueUsers,
             COUNT(DISTINCT sessionId) AS uniqueSessions,
             SUM(messageCount) AS totalMessages
      FROM dbo.Chats
      WHERE updatedAt > @sinceUtc
      GROUP BY CAST(updatedAt AS DATE)
      ORDER BY usageDate DESC
    `);
  return result.recordset;
}

async function fetchKeywordIncidents(sinceUtc, watchTerms) {
  const incidents = await fetchFlaggedIncidents(sinceUtc, "low");
  const loweredTerms = (watchTerms || []).map((term) => term.toLowerCase());
  return incidents.filter((incident) => loweredTerms.some((term) => incident.userMessage.toLowerCase().includes(term)));
}

async function fetchLeadershipSummary(sinceUtc) {
  const incidents = await fetchFlaggedIncidents(sinceUtc, "low");
  const categoryBreakdown = {};
  const severityBreakdown = {};
  const users = new Set();
  for (const incident of incidents) {
    categoryBreakdown[incident.filterType] = (categoryBreakdown[incident.filterType] || 0) + 1;
    severityBreakdown[incident.severity] = (severityBreakdown[incident.severity] || 0) + 1;
    if (incident.userId) users.add(incident.userId);
  }
  return {
    generatedAt: new Date().toISOString(),
    totalFlaggedIncidents: incidents.length,
    highSeverityIncidents: incidents.filter((i) => severityMeetsThreshold(i.severity, "high")).length,
    uniqueImpactedUsers: users.size,
    categoryBreakdown,
    severityBreakdown,
  };
}

async function fetchTeacherSummary(sinceUtc) {
  const incidents = await fetchFlaggedIncidents(sinceUtc, "low");
  const patternCounts = {};
  for (const incident of incidents) {
    patternCounts[incident.filterType] = (patternCounts[incident.filterType] || 0) + 1;
  }
  const recurringRiskPatterns = Object.entries(patternCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([label, count]) => `Repeated concern in ${label} (${count} occurrences)`);
  const mediumOrHigherIncidents = incidents.filter((incident) => severityMeetsThreshold(incident.severity, "medium")).length;
  return {
    generatedAt: new Date().toISOString(),
    blockedSearches: incidents.length,
    mediumOrHigherIncidents,
    recurringRiskPatterns,
    referralRequired: mediumOrHigherIncidents > 0,
  };
}

function htmlList(items) {
  return `<ul>${items.map((item) => `<li>${item}</li>`).join("")}</ul>`;
}

function renderDslIncidentEmail(schoolName, incidents) {
  return `
    <html><body>
      <h1>${schoolName} safeguarding incidents</h1>
      <p>Detailed DSL-only safeguarding review for new incidents.</p>
      ${htmlList(
        incidents.map(
          (incident) => `<strong>${incident.displayName}</strong> — ${incident.filterType} / ${incident.severity} — ${new Date(incident.timestamp).toISOString()}<br/>Action: ${incident.actionTaken}<br/>Message: ${incident.userMessage.slice(0, 200)}`
        )
      )}
    </body></html>
  `;
}

function renderUsageSummaryEmail(schoolName, summaries) {
  return `
    <html><body>
      <h1>${schoolName} usage summary</h1>
      <p>Aggregate-only metrics. No raw student messages are included.</p>
      ${htmlList(summaries.map((summary) => `${summary.usageDate} — users: ${summary.uniqueUsers}, sessions: ${summary.uniqueSessions}, messages: ${summary.totalMessages}`))}
    </body></html>
  `;
}

function renderKeywordWatchEmail(schoolName, incidents, watchTerms) {
  return `
    <html><body>
      <h1>${schoolName} keyword watch</h1>
      <p>Configured safeguarding watch terms: ${watchTerms.join(", ")}</p>
      ${htmlList(incidents.map((incident) => `<strong>${incident.displayName}</strong> — ${incident.filterType} / ${incident.severity} — ${new Date(incident.timestamp).toISOString()}`))}
    </body></html>
  `;
}

function renderLeadershipSummaryEmail(schoolName, summary) {
  return `
    <html><body>
      <h1>${schoolName} leadership safeguarding summary</h1>
      <p>Anonymous oversight summary only. No pupil content is included.</p>
      <ul>
        <li>Total flagged incidents: ${summary.totalFlaggedIncidents}</li>
        <li>High severity incidents: ${summary.highSeverityIncidents}</li>
        <li>Unique impacted users: ${summary.uniqueImpactedUsers}</li>
      </ul>
      <h2>Category breakdown</h2>
      ${htmlList(Object.entries(summary.categoryBreakdown).map(([label, count]) => `${label}: ${count}`))}
      <h2>Severity breakdown</h2>
      ${htmlList(Object.entries(summary.severityBreakdown).map(([label, count]) => `${label}: ${count}`))}
    </body></html>
  `;
}

function renderTeacherSummaryEmail(schoolName, summary) {
  return `
    <html><body>
      <h1>${schoolName} teacher safeguarding summary</h1>
      <p>Summary-only school safeguarding awareness. No raw student messages are included.</p>
      <ul>
        <li>Blocked/flagged searches: ${summary.blockedSearches}</li>
        <li>Medium or higher safeguarding incidents: ${summary.mediumOrHigherIncidents}</li>
        <li>Referral required: ${summary.referralRequired ? "Yes" : "No"}</li>
      </ul>
      <h2>Recurring risk patterns</h2>
      ${htmlList(summary.recurringRiskPatterns)}
      ${summary.referralRequired ? '<p><strong>Action:</strong> Refer safeguarding concerns to the DSL for detailed review.</p>' : ''}
    </body></html>
  `;
}

function createCsvAttachment(incidents) {
  const rows = [
    ["student_identifier", "filter_type", "severity", "action_taken", "timestamp_utc", "message_excerpt"],
    ...incidents.map((incident) => [incident.displayName, incident.filterType, incident.severity, incident.actionTaken, new Date(incident.timestamp).toISOString(), incident.userMessage.slice(0, 200)]),
  ];
  const csv = rows.map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(",")).join("\n");
  return {
    name: "safeguarding-incidents.csv",
    contentType: "text/csv",
    contentInBase64: Buffer.from(csv, "utf-8").toString("base64"),
  };
}

async function sendEmail({ subject, html, recipients, attachments = [] }) {
  const connectionString = process.env.ACS_CONNECTION_STRING;
  const senderAddress = process.env.EMAIL_FROM;
  if (!connectionString || !senderAddress) {
    throw new Error("ACS email settings are missing on backend app");
  }
  const client = EmailClient.fromConnectionString(connectionString);
  const poller = await client.beginSend({
    senderAddress,
    recipients: { to: recipients.map((address) => ({ address })) },
    content: { subject, html },
    attachments,
  });
  const result = await poller.pollUntilDone();
  console.log(`[REPORTING] ACS email send complete status=${result?.status || 'unknown'} subject=${subject}`);
}

function parseEmails(value) {
  return (value || "").split(",").map((item) => item.trim()).filter(Boolean);
}

function getSettings() {
  return {
    schoolName: process.env.SCHOOL_NAME || "SchoolGPT",
    dslEmail: process.env.DSL_EMAIL || "",
    summaryEmails: parseEmails(process.env.SUMMARY_EMAILS),
    leadershipEmails: parseEmails(process.env.LEADERSHIP_EMAILS),
    teacherSummaryEmails: parseEmails(process.env.TEACHER_SUMMARY_EMAILS),
    enableCsvExport: String(process.env.ENABLE_CSV_EXPORT || "true").toLowerCase() === "true",
    csvExportThreshold: Number(process.env.CSV_EXPORT_THRESHOLD || "10"),
    reportingInitialWatermark: new Date(process.env.REPORTING_INITIAL_WATERMARK || "2026-01-01T00:00:00Z"),
    keywordWatchTerms: parseEmails((process.env.KEYWORD_WATCH_TERMS || "").replace(/,/g, ",")),
    dslMinSeverity: process.env.DSL_MIN_SEVERITY || "medium",
    reportingAuditRetentionDays: Number(process.env.REPORTING_AUDIT_RETENTION_DAYS || "90"),
  };
}

async function runDslDailyReport() {
  const settings = getSettings();
  const since = await getWatermark("dsl_daily_report", settings.reportingInitialWatermark);
  const incidents = await fetchFlaggedIncidents(since, settings.dslMinSeverity);
  if (!incidents.length) {
    await recordAudit("dsl_daily_report", "ReportExecution", "DSL daily report executed with no new incidents", { reasonCode: "ScheduledReportRun", additionalData: { since, incidentCount: 0 } });
    return { count: 0, sent: false };
  }
  const attachments = settings.enableCsvExport && incidents.length > settings.csvExportThreshold ? [createCsvAttachment(incidents)] : [];
  await sendEmail({
    subject: `${settings.schoolName} safeguarding incidents`,
    html: renderDslIncidentEmail(settings.schoolName, incidents),
    recipients: [settings.dslEmail],
    attachments,
  });
  await recordAudit("dsl_daily_report", "ReportEmailDispatch", "DSL safeguarding report email dispatched", { reasonCode: "ScheduledReportDispatch", recipients: [settings.dslEmail], additionalData: { incidentCount: incidents.length } });
  await updateWatermark("dsl_daily_report", new Date(incidents[incidents.length - 1].timestamp));
  await recordAudit("dsl_daily_report", "ReportExecution", "DSL daily report completed successfully", { reasonCode: "ScheduledReportRun", additionalData: { incidentCount: incidents.length } });
  return { count: incidents.length, sent: true };
}

async function runUsageDailyReport() {
  const settings = getSettings();
  const since = await getWatermark("usage_daily_report", settings.reportingInitialWatermark);
  const summaries = await fetchUsageSummaries(since);
  if (!summaries.length) {
    await recordAudit("usage_daily_report", "ReportExecution", "Usage report executed with no new aggregate data", { reasonCode: "ScheduledReportRun", additionalData: { since, summaryCount: 0 } });
    return { count: 0, sent: false };
  }
  if (!settings.summaryEmails.length) {
    await recordAudit("usage_daily_report", "ReportExecution", "Usage summary skipped because no recipients are configured", { severity: "Warning", reasonCode: "MissingRecipients", additionalData: { summaryCount: summaries.length } });
    return { count: summaries.length, sent: false };
  }
  await sendEmail({
    subject: `${settings.schoolName} usage summary`,
    html: renderUsageSummaryEmail(settings.schoolName, summaries),
    recipients: settings.summaryEmails,
  });
  await recordAudit("usage_daily_report", "ReportEmailDispatch", "Usage summary report email dispatched", { reasonCode: "ScheduledReportDispatch", recipients: settings.summaryEmails, additionalData: { summaryCount: summaries.length } });
  await updateWatermark("usage_daily_report", new Date(summaries[0].usageDate));
  await recordAudit("usage_daily_report", "ReportExecution", "Usage summary report completed successfully", { reasonCode: "ScheduledReportRun", additionalData: { summaryCount: summaries.length } });
  return { count: summaries.length, sent: true };
}

async function runKeywordWatchReport() {
  const settings = getSettings();
  const since = await getWatermark("dsl_keyword_watch_report", settings.reportingInitialWatermark);
  const incidents = await fetchKeywordIncidents(since, settings.keywordWatchTerms);
  if (!incidents.length) {
    await recordAudit("dsl_keyword_watch_report", "ReportExecution", "Keyword-watch report executed with no matching incidents", { reasonCode: "ScheduledReportRun", additionalData: { since, incidentCount: 0, watchTerms: settings.keywordWatchTerms } });
    return { count: 0, sent: false };
  }
  await sendEmail({
    subject: `${settings.schoolName} keyword watch`,
    html: renderKeywordWatchEmail(settings.schoolName, incidents, settings.keywordWatchTerms),
    recipients: [settings.dslEmail],
  });
  await recordAudit("dsl_keyword_watch_report", "ReportEmailDispatch", "Keyword-watch report email dispatched", { reasonCode: "ScheduledReportDispatch", recipients: [settings.dslEmail], additionalData: { incidentCount: incidents.length, watchTerms: settings.keywordWatchTerms } });
  await updateWatermark("dsl_keyword_watch_report", new Date(incidents[incidents.length - 1].timestamp));
  await recordAudit("dsl_keyword_watch_report", "ReportExecution", "Keyword-watch report completed successfully", { reasonCode: "ScheduledReportRun", additionalData: { incidentCount: incidents.length, watchTerms: settings.keywordWatchTerms } });
  return { count: incidents.length, sent: true };
}

async function runLeadershipSummaryReport() {
  const settings = getSettings();
  const since = await getWatermark("leadership_summary_report", settings.reportingInitialWatermark);
  const summary = await fetchLeadershipSummary(since);
  if (!settings.leadershipEmails.length) {
    await recordAudit("leadership_summary_report", "ReportExecution", "Leadership summary skipped because no recipients are configured", { severity: "Warning", reasonCode: "MissingRecipients", additionalData: { totalFlaggedIncidents: summary.totalFlaggedIncidents } });
    return { count: summary.totalFlaggedIncidents, sent: false };
  }
  await sendEmail({
    subject: `${settings.schoolName} safeguarding leadership summary`,
    html: renderLeadershipSummaryEmail(settings.schoolName, summary),
    recipients: settings.leadershipEmails,
  });
  await recordAudit("leadership_summary_report", "ReportEmailDispatch", "Leadership anonymised summary email dispatched", { reasonCode: "ScheduledReportDispatch", recipients: settings.leadershipEmails, additionalData: { totalFlaggedIncidents: summary.totalFlaggedIncidents } });
  await updateWatermark("leadership_summary_report", new Date(summary.generatedAt));
  await recordAudit("leadership_summary_report", "ReportExecution", "Leadership summary report completed successfully", { reasonCode: "ScheduledReportRun", additionalData: { totalFlaggedIncidents: summary.totalFlaggedIncidents } });
  return { count: summary.totalFlaggedIncidents, sent: true };
}

async function runTeacherSummaryReport() {
  const settings = getSettings();
  const since = await getWatermark("teacher_summary_report", settings.reportingInitialWatermark);
  const summary = await fetchTeacherSummary(since);
  if (!settings.teacherSummaryEmails.length) {
    await recordAudit("teacher_summary_report", "ReportExecution", "Teacher summary skipped because no recipients are configured", { severity: "Warning", reasonCode: "MissingRecipients", additionalData: { blockedSearches: summary.blockedSearches } });
    return { count: summary.blockedSearches, sent: false };
  }
  await sendEmail({
    subject: `${settings.schoolName} safeguarding summary for staff`,
    html: renderTeacherSummaryEmail(settings.schoolName, summary),
    recipients: settings.teacherSummaryEmails,
  });
  await recordAudit("teacher_summary_report", "ReportEmailDispatch", "Teacher summary email dispatched", { reasonCode: "ScheduledReportDispatch", recipients: settings.teacherSummaryEmails, additionalData: { blockedSearches: summary.blockedSearches } });
  await updateWatermark("teacher_summary_report", new Date(summary.generatedAt));
  await recordAudit("teacher_summary_report", "ReportExecution", "Teacher summary report completed successfully", { reasonCode: "ScheduledReportRun", additionalData: { blockedSearches: summary.blockedSearches } });
  return { count: summary.blockedSearches, sent: true };
}

async function runReportingRetention() {
  const settings = getSettings();
  const deletedAudit = await sqlPool()
    .request()
    .input("retentionDays", sql.Int, settings.reportingAuditRetentionDays)
    .query(`DELETE FROM dbo.ReportingAuditLog WHERE Timestamp < DATEADD(day, -@retentionDays, SYSUTCDATETIME())`);
  await recordAudit("reporting_retention", "RetentionExecution", "Reporting retention policy applied", { reasonCode: "RetentionCleanup", additionalData: { deleted: deletedAudit.rowsAffected?.[0] || 0, retentionDays: settings.reportingAuditRetentionDays } });
  return { count: deletedAudit.rowsAffected?.[0] || 0, sent: false };
}

module.exports = {
  runDslDailyReport,
  runUsageDailyReport,
  runKeywordWatchReport,
  runLeadershipSummaryReport,
  runTeacherSummaryReport,
  runReportingRetention,
};
