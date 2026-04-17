class ReportingError extends Error {
  constructor({ code, message, report, retryable = false, status = 500, cause = null }) {
    super(message);
    this.name = "ReportingError";
    this.code = code;
    this.report = report;
    this.retryable = retryable;
    this.status = status;
    this.cause = cause;
  }
}

function createReportingErrorResponse(error, { report, requestId }) {
  const normalized = normalizeReportingError(error, report);
  return {
    status: normalized.status,
    body: {
      ok: false,
      error: {
        code: normalized.code,
        message: normalized.message,
        report: normalized.report,
        retryable: normalized.retryable,
        requestId,
      },
    },
  };
}

function normalizeReportingError(error, report) {
  if (error instanceof ReportingError) {
    return error;
  }

  const message = error?.message || "Reporting execution failed";
  return new ReportingError({
    code: "reporting_execution_failed",
    message,
    report,
    retryable: true,
    status: 500,
    cause: error,
  });
}

module.exports = {
  ReportingError,
  createReportingErrorResponse,
  normalizeReportingError,
};
