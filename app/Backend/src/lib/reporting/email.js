const { EmailClient } = require("@azure/communication-email");
const { ReportingError } = require("./errors");

function createEmailSender(deps = {}) {
  const Client = deps.EmailClient || EmailClient;

  return async function sendEmail({ subject, html, recipients, attachments = [], report }) {
    const connectionString = process.env.ACS_CONNECTION_STRING;
    const senderAddress = process.env.EMAIL_FROM;

    if (!connectionString || !senderAddress) {
      throw new ReportingError({
        code: "reporting_email_not_configured",
        message: "ACS email settings are missing on backend app",
        report,
        retryable: false,
        status: 500,
      });
    }

    const client = typeof Client.fromConnectionString === "function"
      ? Client.fromConnectionString(connectionString)
      : new Client(connectionString);
    const poller = await client.beginSend({
      senderAddress,
      recipients: { to: recipients.map((address) => ({ address })) },
      content: { subject, html },
      attachments,
    });
    const result = await poller.pollUntilDone();
    console.log(`[REPORTING] ACS email send complete status=${result?.status || "unknown"} subject=${subject}`);
  };
}

const sendEmail = createEmailSender();

module.exports = {
  createEmailSender,
  sendEmail,
};
