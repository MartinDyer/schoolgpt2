// src/lib/openai.js
// Azure OpenAI config + utilities (unchanged behavior)

const axios = require("axios");

const endpointBase = (process.env.AZURE_OPENAI_ENDPOINT || "").replace(/\/$/, "");
const deployment = process.env.AZURE_OPENAI_DEPLOYMENT;
const apiVersion = process.env.AZURE_OPENAI_API_VERSION || "2025-01-01-preview";
const chatUrl = `${endpointBase}/openai/deployments/${deployment}/chat/completions?api-version=${apiVersion}`;

const headers = {
  "Content-Type": "application/json",
  "api-key": process.env.AZURE_OPENAI_API_KEY || "",
};

const refusalText =
  "I’m unable to assist you with that request due to safety guidelines. If you’d like, I can help with safer, educational alternatives.";

const isContentFilterErr = (err) => {
  const code = err?.response?.data?.error?.code || "";
  const inner = err?.response?.data?.error?.innererror?.code || "";
  const msg = err?.response?.data?.error?.message || "";
  return /content[_\s-]?filter/i.test(code) ||
    /ResponsibleAIPolicyViolation/i.test(inner) ||
    /content management policy/i.test(msg);
};

const choiceFiltered = (choice) => {
  const fr = (choice?.finish_reason || "").toLowerCase();
  const cfr = choice?.content_filter_results;
  return (
    fr === "content_filter" ||
    cfr?.hate?.filtered ||
    cfr?.self_harm?.filtered ||
    cfr?.sexual?.filtered ||
    cfr?.violence?.filtered
  );
};

module.exports = {
  axios,
  chatUrl,
  headers,
  refusalText,
  isContentFilterErr,
  choiceFiltered,
};
