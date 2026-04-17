const { sqlPool } = require("../db");

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

module.exports = {
  ensureReportingTables,
};
