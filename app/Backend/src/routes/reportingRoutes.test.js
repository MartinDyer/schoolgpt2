const test = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");
const express = require("express");

process.env.NO_SQL_BOOTSTRAP = "1";

const { createReportingRouter } = require("./reportingRoutes");
const { ReportingError } = require("../lib/reporting/errors");

function startServer(router) {
  const app = express();
  app.use((req, res, next) => {
    req.requestId = "req-test-123";
    next();
  });
  app.use("/api", router);

  return new Promise((resolve) => {
    const server = app.listen(0, "127.0.0.1", () => {
      resolve(server);
    });
  });
}

function postJson(server, path, headers = {}) {
  const address = server.address();
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: "127.0.0.1",
        port: address.port,
        path,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...headers,
        },
      },
      (res) => {
        let body = "";
        res.setEncoding("utf8");
        res.on("data", (chunk) => {
          body += chunk;
        });
        res.on("end", () => {
          resolve({ statusCode: res.statusCode, body: JSON.parse(body) });
        });
      }
    );

    req.on("error", reject);
    req.write("{}");
    req.end();
  });
}

test("reporting route returns stable success contract", async (t) => {
  process.env.REPORTING_API_KEY = "test-key";
  const server = await startServer(
    createReportingRouter({
      runUsageDailyReport: async () => ({ count: 2, sent: true }),
    })
  );

  t.after(() => server.close());

  const response = await postJson(server, "/api/reporting/run/usage-daily", {
    "x-reporting-key": "test-key",
  });

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, {
    ok: true,
    report: "usage-daily",
    count: 2,
    sent: true,
  });
});

test("reporting route returns stable error contract", async (t) => {
  process.env.REPORTING_API_KEY = "test-key";
  const server = await startServer(
    createReportingRouter({
      runUsageDailyReport: async () => {
        throw new ReportingError({
          code: "reporting_execution_failed",
          message: "Usage query failed",
          report: "usage-daily",
          retryable: true,
          status: 503,
        });
      },
    })
  );

  t.after(() => server.close());

  const response = await postJson(server, "/api/reporting/run/usage-daily", {
    "x-reporting-key": "test-key",
  });

  assert.equal(response.statusCode, 503);
  assert.deepEqual(response.body, {
    ok: false,
    error: {
      code: "reporting_execution_failed",
      message: "Usage query failed",
      report: "usage-daily",
      retryable: true,
      requestId: "req-test-123",
    },
  });
});

test("reporting route returns stable lock contention contract", async (t) => {
  process.env.REPORTING_API_KEY = "test-key";
  const server = await startServer(
    createReportingRouter({
      runUsageDailyReport: async () => {
        throw new ReportingError({
          code: "reporting_execution_locked",
          message: "Report 'usage-daily' is already running",
          report: "usage-daily",
          retryable: true,
          status: 409,
        });
      },
    })
  );

  t.after(() => server.close());

  const response = await postJson(server, "/api/reporting/run/usage-daily", {
    "x-reporting-key": "test-key",
  });

  assert.equal(response.statusCode, 409);
  assert.deepEqual(response.body, {
    ok: false,
    error: {
      code: "reporting_execution_locked",
      message: "Report 'usage-daily' is already running",
      report: "usage-daily",
      retryable: true,
      requestId: "req-test-123",
    },
  });
});

test("reporting route returns stable unauthorized contract", async (t) => {
  process.env.REPORTING_API_KEY = "test-key";
  const server = await startServer(createReportingRouter());

  t.after(() => server.close());

  const response = await postJson(server, "/api/reporting/run/dsl-daily", {
    "x-reporting-key": "wrong-key",
  });

  assert.equal(response.statusCode, 401);
  assert.deepEqual(response.body, {
    ok: false,
    error: {
      code: "reporting_unauthorized",
      message: "Unauthorized reporting request",
      report: "unknown",
      retryable: false,
      requestId: "req-test-123",
    },
  });
});
