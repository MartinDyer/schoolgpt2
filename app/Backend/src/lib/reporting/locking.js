const { sql, sqlPool } = require("../db");
const { ReportingError } = require("./errors");

function createLockResource(reportName) {
  return `schoolgpt.reporting.${reportName}`;
}

async function withReportExecutionLock(report, reportName, operation) {
  const resource = createLockResource(reportName);
  const pool = sqlPool();

  const acquireResult = await pool
    .request()
    .input("resource", sql.NVarChar(255), resource)
    .query(`
      DECLARE @result INT;
      EXEC @result = sp_getapplock
        @Resource = @resource,
        @LockMode = 'Exclusive',
        @LockOwner = 'Session',
        @LockTimeout = 0;
      SELECT @result AS lockResult;
    `);

  const lockResult = acquireResult.recordset[0]?.lockResult;
  if (typeof lockResult !== "number" || lockResult < 0) {
    throw new ReportingError({
      code: "reporting_execution_locked",
      message: `Report '${report}' is already running`,
      report,
      retryable: true,
      status: 409,
    });
  }

  try {
    return await operation();
  } finally {
    await pool
      .request()
      .input("resource", sql.NVarChar(255), resource)
      .query(`
        EXEC sp_releaseapplock
          @Resource = @resource,
          @LockOwner = 'Session';
      `);
  }
}

module.exports = {
  createLockResource,
  withReportExecutionLock,
};
