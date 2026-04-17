const { sql, sqlPool } = require("../db");
const { ensureReportingTables } = require("./tables");

function coerceDate(value) {
  return value instanceof Date ? value : new Date(value);
}

async function getWatermark(reportName, initialValue) {
  await ensureReportingTables();
  const result = await sqlPool()
    .request()
    .input("reportName", sql.NVarChar(100), reportName)
    .input("initialValue", sql.DateTime2, initialValue)
    .query(`
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF NOT EXISTS (
  SELECT 1
  FROM dbo.ReportingWatermarks WITH (UPDLOCK, HOLDLOCK)
  WHERE ReportName = @reportName
)
BEGIN
  INSERT INTO dbo.ReportingWatermarks (ReportName, LastProcessedAt)
  VALUES (@reportName, @initialValue);
END;

SELECT LastProcessedAt
FROM dbo.ReportingWatermarks
WHERE ReportName = @reportName;

COMMIT TRANSACTION;
`);

  return coerceDate(result.recordset[0]?.LastProcessedAt || initialValue);
}

async function updateWatermark(reportName, newValue) {
  await ensureReportingTables();
  await sqlPool()
    .request()
    .input("reportName", sql.NVarChar(100), reportName)
    .input("lastProcessedAt", sql.DateTime2, newValue)
    .query(`
      MERGE dbo.ReportingWatermarks WITH (HOLDLOCK) AS target
      USING (SELECT @reportName AS ReportName, @lastProcessedAt AS LastProcessedAt) AS source
      ON target.ReportName = source.ReportName
      WHEN MATCHED THEN UPDATE SET LastProcessedAt = source.LastProcessedAt, UpdatedAt = SYSUTCDATETIME()
      WHEN NOT MATCHED THEN INSERT (ReportName, LastProcessedAt) VALUES (source.ReportName, source.LastProcessedAt);
    `);
}

module.exports = {
  coerceDate,
  getWatermark,
  updateWatermark,
};
