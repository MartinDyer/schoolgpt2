// src/lib/openai.js
// Azure OpenAI config + utilities (unchanged behavior)

const { DefaultAzureCredential, getBearerTokenProvider } = require("@azure/identity");

const endpointBase = (process.env.AZURE_OPENAI_ENDPOINT || "").replace(/\/$/, "");
const deployment = process.env.AZURE_OPENAI_DEPLOYMENT;
const apiVersion = process.env.AZURE_OPENAI_API_VERSION || "2025-01-01-preview";
const chatUrl = `${endpointBase}/openai/deployments/${deployment}/chat/completions?api-version=${apiVersion}`;

// Token provider for Managed Identity (scopes for Cognitive Services)
const credential = new DefaultAzureCredential();
const scope = "https://cognitiveservices.azure.com/.default";
const getAccessToken = getBearerTokenProvider(credential, scope);

// Dynamic headers builder
const getHeaders = async () => {
  const common = { "Content-Type": "application/json" };
  // 1. Prefer API Key if explicitly set (local dev or fallback)
  if (process.env.AZURE_OPENAI_API_KEY) {
    return { ...common, "api-key": process.env.AZURE_OPENAI_API_KEY };
  }
  // 2. Use Managed Identity Token
  try {
    const token = await getAccessToken();
    return { ...common, "Authorization": `Bearer ${token}` };
  } catch (e) {
    console.error("[AUTH] Failed to get Managed Identity token:", e.message);
    throw e;
  }
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
