const test = require("node:test");
const assert = require("node:assert/strict");

const { ReportingError } = require("./errors");
const { createEmailSender } = require("./email");

test("email sender rejects missing ACS settings", async () => {
  delete process.env.ACS_CONNECTION_STRING;
  delete process.env.EMAIL_FROM;

  const sendEmail = createEmailSender();

  await assert.rejects(
    () => sendEmail({ subject: "Subject", html: "<p>x</p>", recipients: ["dsl@example.com"], report: "dsl-daily" }),
    (error) => {
      assert.ok(error instanceof ReportingError);
      assert.equal(error.code, "reporting_email_not_configured");
      assert.equal(error.report, "dsl-daily");
      return true;
    }
  );
});

test("email sender uses ACS client with expected payload", async () => {
  process.env.ACS_CONNECTION_STRING = "endpoint=https://example/;accesskey=test";
  process.env.EMAIL_FROM = "reporting@example.com";

  const observed = {};

  class FakeEmailClient {
    constructor(connectionString) {
      observed.connectionString = connectionString;
    }

    async beginSend(payload) {
      observed.payload = payload;
      return {
        async pollUntilDone() {
          return { status: "Succeeded" };
        },
      };
    }
  }

  const sendEmail = createEmailSender({ EmailClient: FakeEmailClient });
  await sendEmail({
    subject: "Subject",
    html: "<p>Hello</p>",
    recipients: ["dsl@example.com", "teacher@example.com"],
    attachments: [{ name: "file.csv" }],
    report: "usage-daily",
  });

  assert.equal(observed.connectionString, process.env.ACS_CONNECTION_STRING);
  assert.deepEqual(observed.payload, {
    senderAddress: "reporting@example.com",
    recipients: {
      to: [{ address: "dsl@example.com" }, { address: "teacher@example.com" }],
    },
    content: { subject: "Subject", html: "<p>Hello</p>" },
    attachments: [{ name: "file.csv" }],
  });
});

test("email sender supports static fromConnectionString client factories", async () => {
  process.env.ACS_CONNECTION_STRING = "endpoint=https://example/;accesskey=test";
  process.env.EMAIL_FROM = "reporting@example.com";

  const observed = {};

  class FakeFactoryClient {
    static fromConnectionString(connectionString) {
      observed.connectionString = connectionString;
      return {
        async beginSend(payload) {
          observed.payload = payload;
          return {
            async pollUntilDone() {
              return { status: "Succeeded" };
            },
          };
        },
      };
    }
  }

  const sendEmail = createEmailSender({ EmailClient: FakeFactoryClient });
  await sendEmail({
    subject: "Factory Subject",
    html: "<p>Factory</p>",
    recipients: ["dsl@example.com"],
    report: "dsl-daily",
  });

  assert.equal(observed.connectionString, process.env.ACS_CONNECTION_STRING);
  assert.deepEqual(observed.payload, {
    senderAddress: "reporting@example.com",
    recipients: {
      to: [{ address: "dsl@example.com" }],
    },
    content: { subject: "Factory Subject", html: "<p>Factory</p>" },
    attachments: [],
  });
});
