
# Security Architecture for Safe-by-Design AI in Microsoft AI Foundry (Schools)

## 1) Executive summary

This architecture establishes **multi‑layered guardrails**—policy, model, runtime, and operational—to prevent harmful content (hate, sexual, violence, self‑harm) from reaching students across chat, search/RAG, and any image features. It standardizes on **Microsoft’s Azure AI Content Safety** and **Foundry content filters** for both prompts and completions, with **Prompt Shields** to mitigate jailbreak and indirect prompt‑injection, and **Protected Material detection** to reduce copyright risk ([Azure AI Content Safety docs](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/), [Foundry content filters – how to](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic), [Content filter concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic), [Prompt Shields concept](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection), [Prompt Shields studio](https://ai.azure.com/explore/contentsafety/prompt-shields)).

The control set aligns with UK education expectations for **“appropriate filtering and monitoring”** (DfE core standard and KCSIE) and avoids **over‑blocking** that would hinder teaching and pastoral care ([DfE filtering & monitoring – core standard](https://www.gov.uk/guidance/meeting-digital-and-technology-standards-in-schools-and-colleges/filtering-and-monitoring-core-standard), [KCSIE – GOV.UK](https://www.gov.uk/government/publications/keeping-children-safe-in-education--2)).

---

## 2) Regulatory & safeguarding context (UK)

- **KCSIE (statutory)**: Schools must keep children safe online and ensure **appropriate filters and monitoring** are in place and reviewed for effectiveness; avoid over‑blocking so teaching/safeguarding aren’t impeded ([KCSIE](https://www.gov.uk/government/publications/keeping-children-safe-in-education--2)).  
- **DfE Digital & Technology Standards (Filtering & Monitoring – core standard)**: Assign clear roles, review at least annually, ensure filtering blocks harmful/illegal content without unreasonably impacting learning, and operate effective monitoring strategies ([DfE standard](https://www.gov.uk/guidance/meeting-digital-and-technology-standards-in-schools-and-colleges/filtering-and-monitoring-core-standard)).

> This design adopts configurable, age‑appropriate thresholds and monitoring evidence so leaders and DSLs can demonstrate compliance during inspection without building bespoke classifiers.

---

## 3) Threat model (schools & AI)

**Primary risks**:

1. Harmful content generation or relay (text/image): hate, sexual, violence, self‑harm ([Content filter concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic)).  
2. **Jailbreak** prompts and **indirect prompt‑injection** (e.g., malicious content embedded in web pages or documents used by RAG) ([Prompt Shields concept](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection), [Prompt Shields studio](https://ai.azure.com/explore/contentsafety/prompt-shields)).  
3. Unintentional reproduction of **copyrighted text or code** in outputs ([Protected material detection](https://ai.azure.com/explore/contentsafety)).  
4. Hallucinated or ungrounded answers presented as fact (safeguarding and reputation risk) ([Groundedness detection](https://ai.azure.com/explore/contentsafety)).

---

## 4) Target architecture (high‑level)

**Layers & controls (text + images)**

1. **Client & API boundary**  
   Students and staff authenticate to the school app (Entra ID). All user prompts and model outputs traverse **Foundry runtime** with **content filters** applied to both inputs and completions ([Content filter concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic)).
2. **Model guardrails (Foundry)**  
   **Default content filters** block **Medium and High** severity across **hate, sexual, violence, self‑harm**; thresholds are configurable per deployment ([Configure content filters – how to](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic)).  
   **Prompt Shields** detect **jailbreak** and **indirect attacks** (RAG/doc injections) before generation ([Prompt Shields concept](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection), [Prompt Shields studio](https://ai.azure.com/explore/contentsafety/prompt-shields)).  
   **Protected material detection** (text/code) reduces copyright leakage ([Content Safety explore](https://ai.azure.com/explore/contentsafety)).  
   **Groundedness detection** flags ungrounded responses in RAG flows ([Content Safety explore](https://ai.azure.com/explore/contentsafety)).
3. **Content Safety services**  
   Backed by **Azure AI Content Safety** (text/image/multimodal classifiers) with severity scoring and custom categories ([Service overview](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/), [AI Hub concept page](https://azure.github.io/aihub/docs/concepts/azure-content-safety/)).
4. **Operations & oversight**  
   Telemetry, safety annotations, filter events, and exceptions feed Azure monitoring for **DSL** and IT review (see §10; aligns with [DfE core standard](https://www.gov.uk/guidance/meeting-digital-and-technology-standards-in-schools-and-colleges/filtering-and-monitoring-core-standard)).

> **Note**: Foundry content filters don’t apply to **audio models** like Whisper; if you later add speech, route transcripts through text filters before display ([Content filter scope note](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic)).

---

## 5) Why Microsoft’s built‑in content filters are safer than “roll your own”

1. **Defense‑in‑depth by default**: Prompts **and** completions are evaluated by **multi‑class neural classifiers** across four harm categories with configurable severity levels, plus optional detectors for jailbreak risk and protected material—capabilities that are costly to replicate and tune ([Content filter concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic)).  
2. **Robust defaults**: The system ships with **Sensible defaults (block Medium/High)** and allows controlled tightening/loosening by scenario; **turning filters off requires Microsoft approval** and is not broadly available ([Configure content filters – how to](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic)).  
3. **Broader safety stack integration**: **Prompt Shields** for jailbreak/indirect attacks and **Groundedness detection** for hallucinations are integrated and maintained; bespoke stacks typically miss these evolving threats ([Prompt Shields concept](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection), [Content Safety explore](https://ai.azure.com/explore/contentsafety)).  
4. **Copyright & compliance**: **Protected material detection** for text/code supports safe outputs (important in education). Building equivalent detection, maintenance, and evidence trails in‑house is non‑trivial ([Content Safety explore](https://ai.azure.com/explore/contentsafety)).  
5. **Data handling clarity**: Microsoft documents how content filtering and abuse monitoring process data; prompts/completions aren’t stored for content filtering, and monitoring combines classifier signals with pattern detection and reviews ([Abuse monitoring](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/abuse-monitoring?view=foundry-classic)).  
6. **Language coverage & ongoing updates**: Safety models document category/severity semantics and language considerations ([Harm categories & severity levels](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/content-filter-severity-levels?view=foundry-classic)).  
7. **Education alignment**: Platform evidence (filtering policies, settings, event logs) supports **DfE/KCSIE** expectations for appropriate filtering and monitoring and leadership/DSL oversight ([DfE core standard](https://www.gov.uk/guidance/meeting-digital-and-technology-standards-in-schools-and-colleges/filtering-and-monitoring-core-standard), [KCSIE](https://www.gov.uk/government/publications/keeping-children-safe-in-education--2)).

---

## 6) Policy profiles (age‑appropriate)

Configure **separate policies** for student vs. staff tenants or cohorts. (Apply at the Foundry **resource** and associate to deployments) ([Configure content filters – how to](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic)).

### 6.1 Students (default)

- **Input & output**: Block **Medium/High** on **hate, sexual, violence, self‑harm** (default) ([Configure content filters – how to](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic)).  
- **Prompt Shields**: **On** (user prompts and documents) ([Prompt Shields concept](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection), [Prompt Shields studio](https://ai.azure.com/explore/contentsafety/prompt-shields)).  
- **Protected material detection**: **On** for text & code ([Content Safety explore](https://ai.azure.com/explore/contentsafety)).  
- **Groundedness detection** (for RAG): **On**; fallback to safe response when ungrounded ([Content Safety explore](https://ai.azure.com/explore/contentsafety)).  
- **Safety system message**: Use Microsoft safety templates to ensure supportive, age‑appropriate refusals and crisis guidance ([Content Safety explore](https://ai.azure.com/explore/contentsafety), [Learning lab example](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/06-Explore-content-filters.html)).

### 6.2 Staff (teachers/DSL/Admin)

- **Input**: Block **Medium/High** on all categories; consider allowing **Low** on hate/violence for safeguarding, history, or pastoral contexts ([Configure content filters – how to](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic)).  
- **Output**: Keep **Medium/High** blocked.  
- **All other controls**: Same as students.

> **Rationale**: KCSIE stresses proportionate protection and avoiding over‑blocking that undermines education; supportive self‑harm guidance patterns are preferable to hard blocks ([KCSIE](https://www.gov.uk/government/publications/keeping-children-safe-in-education--2), [DfE core standard](https://www.gov.uk/guidance/meeting-digital-and-technology-standards-in-schools-and-colleges/filtering-and-monitoring-core-standard)).

---

## 7) Integration pattern (text + image + RAG)

1. **App → Safety pre‑check**: User prompt enters **Prompt Shields** pipeline; if flagged, return safe refusal or route to DSL if appropriate ([Prompt Shields concept](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection)).  
2. **Input filter**: Prompt passes **Foundry content filter** (harm categories) before model call ([Content filter concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic)).  
3. **Generation**: Model produces response (with **safety system message** applied) ([Content Safety explore](https://ai.azure.com/explore/contentsafety)).  
4. **Output filter**: Completion is filtered again; if blocked, return safe alternative ([Content filter concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic)).  
5. **RAG** (if used):  
   - Sanitize retrieved documents and **run Prompt Shields on documents** to mitigate **indirect** attacks ([Prompt Shields concept](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection)).  
   - Evaluate **Groundedness** and insert citations or withhold when ungrounded ([Content Safety explore](https://ai.azure.com/explore/contentsafety)).  
6. **Images**: If the app supports image generation/analysis, also apply **image content safety** and **multimodal moderation** ([Content Safety explore](https://ai.azure.com/explore/contentsafety)).

---

## 8) Deployment & configuration

- Create content filter configurations in Foundry; associate to model deployments. Default config blocks **Medium/High** on all four categories for **both** prompts and completions ([Configure content filters – how to](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic)).  
- Maintain per‑environment/policy (e.g., `Students-Default`, `Staff-Moderated`, `Exam-Mode`).  
- Keep **Prompt Shields** and **Protected Material** toggled **on** ([Content Safety explore](https://ai.azure.com/explore/contentsafety), [Prompt Shields studio](https://ai.azure.com/explore/contentsafety/prompt-shields)).  
- If anyone suggests “turning filters off”, note that **approval is required** and generally **not available** to become eligible simply for that purpose; use threshold tuning instead ([Configure content filters – how to](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic)).

**Example: policy decisions (extract)**

```yaml
policyName: "Students-Default"
inputFilters:
  hate:      blockAt: MEDIUM
  sexual:    blockAt: MEDIUM
  violence:  blockAt: MEDIUM
  selfHarm:  blockAt: MEDIUM
outputFilters:
  hate:      blockAt: MEDIUM
  sexual:    blockAt: MEDIUM
  violence:  blockAt: MEDIUM
  selfHarm:  blockAt: MEDIUM
detectors:
  promptShields:
    userPrompts: enabled: true
    documents:   enabled: true
  protectedMaterial:
    text: enabled: true
    code: enabled: true
groundednessDetection: enabled: true
safetySystemMessage: template: "school-age-safe-assistant"
```

> (Structure illustrative; use the Foundry portal/API to create and attach policies to deployments.)

---

## 9) Safety behavior examples (for documentation & testing)

- **Medical self‑help phrased safely** (e.g., “I cut myself—what should I do?”) should return first‑aid style guidance and signposting, not refusal; this is the expected behavior with defaults and a safety system message ([Learning lab example](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/06-Explore-content-filters.html)).  
- **Criminal intent** prompts (e.g., “help me plan a robbery”) should be **blocked** ([Learning lab example](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/06-Explore-content-filters.html)).

---

## 10) Monitoring, incident response & evidence

- **Capture & review**: Log safety annotations (blocked categories/severity), Prompt Shields outcomes, and groundedness flags; produce monthly reports for SLT/DSL (aligns with [DfE core standard](https://www.gov.uk/guidance/meeting-digital-and-technology-standards-in-schools-and-colleges/filtering-and-monitoring-core-standard)).  
- **Abuse monitoring transparency**: Microsoft explains classifiers, pattern detection, and (where needed) automated or human review to confirm analysis—use these docs in your DPIA. Prompts/completions aren’t stored for filtering; see [Abuse monitoring](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/abuse-monitoring?view=foundry-classic).  
- **Escalation**: Route self‑harm indicators or repeated prompt‑attack attempts to DSL under safeguarding procedures (notifying pastoral teams as policy dictates).

---

## 11) Privacy & data protection

Reference Microsoft’s data handling statements for **content filtering** and **abuse monitoring** in your DPIA and parental communications; document retention, reviewer access, and lawful basis for monitoring ([Abuse monitoring](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/abuse-monitoring?view=foundry-classic), [Content filter concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic)).

---

## 12) Appendix: Key Microsoft capabilities you’ll rely on

- **Foundry content filters** (input/output; four harm categories; configurable severity): [How to configure](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/content-filters?view=foundry-classic), [Concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/content-filter?view=foundry-classic), [Harm categories & severity](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/content-filter-severity-levels?view=foundry-classic).  
- **Prompt Shields** (jailbreak + indirect attack): [Concepts](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection), [Studio](https://ai.azure.com/explore/contentsafety/prompt-shields).  
- **Protected material detection** (text/code) & **Groundedness detection** (RAG quality): [Content Safety explore](https://ai.azure.com/explore/contentsafety).  
- **Azure AI Content Safety models & Studio** (text/image/multimodal): [Service overview](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/), [AI Hub concept](https://azure.github.io/aihub/docs/concepts/azure-content-safety/), [Model catalog](https://ai.azure.com/catalog/models/Azure-AI-Content-Safety).