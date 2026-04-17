const { sql, sqlPool } = require("../db");
const { recordAudit } = require("./audit");
const { getSettings } = require("./config");
const { sendEmail } = require("./email");
const { withReportExecutionLock } = require("./locking");
const { fetchFlaggedIncidents, fetchKeywordIncidents, fetchLeadershipSummary, fetchTeacherSummary, fetchUsageSummaries } = require("./queries");
const { createCsvAttachment, renderDslIncidentEmail, renderKeywordWatchEmail, renderLeadershipSummaryEmail, renderTeacherSummaryEmail, renderUsageSummaryEmail } = require("./renderers");
const { getWatermark, updateWatermark } = require("./watermarks");

function createReportingRunners(deps = {}) {
  const runtime = {
    sql,
    sqlPool,
    recordAudit,
    getSettings,
    sendEmail,
    fetchFlaggedIncidents,
    fetchKeywordIncidents,
    fetchLeadershipSummary,
    fetchTeacherSummary,
    fetchUsageSummaries,
    createCsvAttachment,
    renderDslIncidentEmail,
    renderKeywordWatchEmail,
    renderLeadershipSummaryEmail,
    renderTeacherSummaryEmail,
    renderUsageSummaryEmail,
    getWatermark,
    updateWatermark,
    withReportExecutionLock,
    ...deps,
  };

  async function runDslDailyReport() {
    const report = "dsl-daily";
    const reportName = "dsl_daily_report";
    return runtime.withReportExecutionLock(report, reportName, async () => {
      const settings = runtime.getSettings();
      const since = await runtime.getWatermark(reportName, settings.reportingInitialWatermark);
      const incidents = await runtime.fetchFlaggedIncidents(since, settings.dslMinSeverity);

      if (!incidents.length) {
        await runtime.recordAudit(reportName, "ReportExecution", "DSL daily report executed with no new incidents", {
          reasonCode: "ScheduledReportRun",
          additionalData: { since, incidentCount: 0 },
        });
        return { count: 0, sent: false };
      }

      const attachments = settings.enableCsvExport && incidents.length > settings.csvExportThreshold ? [runtime.createCsvAttachment(incidents)] : [];
      await runtime.sendEmail({
        subject: `${settings.schoolName} safeguarding incidents`,
        html: runtime.renderDslIncidentEmail(settings.schoolName, incidents),
        recipients: [settings.dslEmail],
        attachments,
        report,
      });
      await runtime.recordAudit(reportName, "ReportEmailDispatch", "DSL safeguarding report email dispatched", {
        reasonCode: "ScheduledReportDispatch",
        recipients: [settings.dslEmail],
        additionalData: { incidentCount: incidents.length },
      });
      await runtime.updateWatermark(reportName, new Date(incidents[incidents.length - 1].timestamp));
      await runtime.recordAudit(reportName, "ReportExecution", "DSL daily report completed successfully", {
        reasonCode: "ScheduledReportRun",
        additionalData: { incidentCount: incidents.length },
      });
      return { count: incidents.length, sent: true };
    });
  }

  async function runUsageDailyReport() {
    const report = "usage-daily";
    const reportName = "usage_daily_report";
    return runtime.withReportExecutionLock(report, reportName, async () => {
      const settings = runtime.getSettings();
      const since = await runtime.getWatermark(reportName, settings.reportingInitialWatermark);
      const { summaries, sourceHighWatermark } = await runtime.fetchUsageSummaries(since);

      if (!summaries.length) {
        await runtime.recordAudit(reportName, "ReportExecution", "Usage report executed with no new aggregate data", {
          reasonCode: "ScheduledReportRun",
          additionalData: { since, summaryCount: 0 },
        });
        return { count: 0, sent: false };
      }

      if (!settings.summaryEmails.length) {
        await runtime.recordAudit(reportName, "ReportExecution", "Usage summary skipped because no recipients are configured", {
          severity: "Warning",
          reasonCode: "MissingRecipients",
          additionalData: { summaryCount: summaries.length },
        });
        return { count: summaries.length, sent: false };
      }

      await runtime.sendEmail({
        subject: `${settings.schoolName} usage summary`,
        html: runtime.renderUsageSummaryEmail(settings.schoolName, summaries),
        recipients: settings.summaryEmails,
        report,
      });
      await runtime.recordAudit(reportName, "ReportEmailDispatch", "Usage summary report email dispatched", {
        reasonCode: "ScheduledReportDispatch",
        recipients: settings.summaryEmails,
        additionalData: { summaryCount: summaries.length },
      });

      if (sourceHighWatermark) {
        await runtime.updateWatermark(reportName, sourceHighWatermark);
      }

      await runtime.recordAudit(reportName, "ReportExecution", "Usage summary report completed successfully", {
        reasonCode: "ScheduledReportRun",
        additionalData: { summaryCount: summaries.length, sourceHighWatermark },
      });
      return { count: summaries.length, sent: true };
    });
  }

  async function runKeywordWatchReport() {
    const report = "keyword-watch";
    const reportName = "dsl_keyword_watch_report";
    return runtime.withReportExecutionLock(report, reportName, async () => {
      const settings = runtime.getSettings();
      const since = await runtime.getWatermark(reportName, settings.reportingInitialWatermark);
      const incidents = await runtime.fetchKeywordIncidents(since, settings.keywordWatchTerms);

      if (!incidents.length) {
        await runtime.recordAudit(reportName, "ReportExecution", "Keyword-watch report executed with no matching incidents", {
          reasonCode: "ScheduledReportRun",
          additionalData: { since, incidentCount: 0, watchTerms: settings.keywordWatchTerms },
        });
        return { count: 0, sent: false };
      }

      await runtime.sendEmail({
        subject: `${settings.schoolName} keyword watch`,
        html: runtime.renderKeywordWatchEmail(settings.schoolName, incidents, settings.keywordWatchTerms),
        recipients: [settings.dslEmail],
        report,
      });
      await runtime.recordAudit(reportName, "ReportEmailDispatch", "Keyword-watch report email dispatched", {
        reasonCode: "ScheduledReportDispatch",
        recipients: [settings.dslEmail],
        additionalData: { incidentCount: incidents.length, watchTerms: settings.keywordWatchTerms },
      });
      await runtime.updateWatermark(reportName, new Date(incidents[incidents.length - 1].timestamp));
      await runtime.recordAudit(reportName, "ReportExecution", "Keyword-watch report completed successfully", {
        reasonCode: "ScheduledReportRun",
        additionalData: { incidentCount: incidents.length, watchTerms: settings.keywordWatchTerms },
      });
      return { count: incidents.length, sent: true };
    });
  }

  async function runLeadershipSummaryReport() {
    const report = "leadership-summary";
    const reportName = "leadership_summary_report";
    return runtime.withReportExecutionLock(report, reportName, async () => {
      const settings = runtime.getSettings();
      const since = await runtime.getWatermark(reportName, settings.reportingInitialWatermark);
      const summary = await runtime.fetchLeadershipSummary(since);

      if (!settings.leadershipEmails.length) {
        await runtime.recordAudit(reportName, "ReportExecution", "Leadership summary skipped because no recipients are configured", {
          severity: "Warning",
          reasonCode: "MissingRecipients",
          additionalData: { totalFlaggedIncidents: summary.totalFlaggedIncidents },
        });
        return { count: summary.totalFlaggedIncidents, sent: false };
      }

      await runtime.sendEmail({
        subject: `${settings.schoolName} safeguarding leadership summary`,
        html: runtime.renderLeadershipSummaryEmail(settings.schoolName, summary),
        recipients: settings.leadershipEmails,
        report,
      });
      await runtime.recordAudit(reportName, "ReportEmailDispatch", "Leadership anonymised summary email dispatched", {
        reasonCode: "ScheduledReportDispatch",
        recipients: settings.leadershipEmails,
        additionalData: { totalFlaggedIncidents: summary.totalFlaggedIncidents },
      });

      if (summary.sourceHighWatermark) {
        await runtime.updateWatermark(reportName, new Date(summary.sourceHighWatermark));
      }

      await runtime.recordAudit(reportName, "ReportExecution", "Leadership summary report completed successfully", {
        reasonCode: "ScheduledReportRun",
        additionalData: {
          totalFlaggedIncidents: summary.totalFlaggedIncidents,
          sourceHighWatermark: summary.sourceHighWatermark,
        },
      });
      return { count: summary.totalFlaggedIncidents, sent: true };
    });
  }

  async function runTeacherSummaryReport() {
    const report = "teacher-summary";
    const reportName = "teacher_summary_report";
    return runtime.withReportExecutionLock(report, reportName, async () => {
      const settings = runtime.getSettings();
      const since = await runtime.getWatermark(reportName, settings.reportingInitialWatermark);
      const summary = await runtime.fetchTeacherSummary(since);

      if (!settings.teacherSummaryEmails.length) {
        await runtime.recordAudit(reportName, "ReportExecution", "Teacher summary skipped because no recipients are configured", {
          severity: "Warning",
          reasonCode: "MissingRecipients",
          additionalData: { blockedSearches: summary.blockedSearches },
        });
        return { count: summary.blockedSearches, sent: false };
      }

      await runtime.sendEmail({
        subject: `${settings.schoolName} safeguarding summary for staff`,
        html: runtime.renderTeacherSummaryEmail(settings.schoolName, summary),
        recipients: settings.teacherSummaryEmails,
        report,
      });
      await runtime.recordAudit(reportName, "ReportEmailDispatch", "Teacher summary email dispatched", {
        reasonCode: "ScheduledReportDispatch",
        recipients: settings.teacherSummaryEmails,
        additionalData: { blockedSearches: summary.blockedSearches },
      });

      if (summary.sourceHighWatermark) {
        await runtime.updateWatermark(reportName, new Date(summary.sourceHighWatermark));
      }

      await runtime.recordAudit(reportName, "ReportExecution", "Teacher summary report completed successfully", {
        reasonCode: "ScheduledReportRun",
        additionalData: {
          blockedSearches: summary.blockedSearches,
          sourceHighWatermark: summary.sourceHighWatermark,
        },
      });
      return { count: summary.blockedSearches, sent: true };
    });
  }

  async function runReportingRetention() {
    const report = "retention";
    const reportName = "reporting_retention";
    return runtime.withReportExecutionLock(report, reportName, async () => {
      const settings = runtime.getSettings();
      const deletedAudit = await runtime.sqlPool()
        .request()
        .input("retentionDays", runtime.sql.Int, settings.reportingAuditRetentionDays)
        .query(`DELETE FROM dbo.ReportingAuditLog WHERE Timestamp < DATEADD(day, -@retentionDays, SYSUTCDATETIME())`);
      await runtime.recordAudit(reportName, "RetentionExecution", "Reporting retention policy applied", {
        reasonCode: "RetentionCleanup",
        additionalData: { deleted: deletedAudit.rowsAffected?.[0] || 0, retentionDays: settings.reportingAuditRetentionDays },
      });
      return { count: deletedAudit.rowsAffected?.[0] || 0, sent: false };
    });
  }

  return {
    runDslDailyReport,
    runUsageDailyReport,
    runKeywordWatchReport,
    runLeadershipSummaryReport,
    runTeacherSummaryReport,
    runReportingRetention,
  };
}

const runners = createReportingRunners();

module.exports = {
  createReportingRunners,
  ...runners,
};
