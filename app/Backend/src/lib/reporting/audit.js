const { randomUUID } = require("crypto");
const { sql, sqlPool } = require("../db");
const { ensureReportingTables } = require("./tables");

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

module.exports = {
  recordAudit,
};
