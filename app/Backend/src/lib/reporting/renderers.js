function htmlList(items) {
  return `<ul>${items.map((item) => `<li>${item}</li>`).join("")}</ul>`;
}

function renderDslIncidentEmail(schoolName, incidents) {
  return `
    <html><body>
      <h1>${schoolName} safeguarding incidents</h1>
      <p>Detailed DSL-only safeguarding review for new incidents.</p>
      ${htmlList(
        incidents.map(
          (incident) => `<strong>${incident.displayName}</strong> — ${incident.filterType} / ${incident.severity} — ${new Date(incident.timestamp).toISOString()}<br/>Action: ${incident.actionTaken}<br/>Message: ${incident.userMessage.slice(0, 200)}`
        )
      )}
    </body></html>
  `;
}

function renderUsageSummaryEmail(schoolName, summaries) {
  return `
    <html><body>
      <h1>${schoolName} usage summary</h1>
      <p>Aggregate-only metrics. No raw student messages are included.</p>
      ${htmlList(summaries.map((summary) => `${summary.usageDate} — users: ${summary.uniqueUsers}, sessions: ${summary.uniqueSessions}, messages: ${summary.totalMessages}`))}
    </body></html>
  `;
}

function renderKeywordWatchEmail(schoolName, incidents, watchTerms) {
  return `
    <html><body>
      <h1>${schoolName} keyword watch</h1>
      <p>Configured safeguarding watch terms: ${watchTerms.join(", ")}</p>
      ${htmlList(incidents.map((incident) => `<strong>${incident.displayName}</strong> — ${incident.filterType} / ${incident.severity} — ${new Date(incident.timestamp).toISOString()}`))}
    </body></html>
  `;
}

function renderLeadershipSummaryEmail(schoolName, summary) {
  return `
    <html><body>
      <h1>${schoolName} leadership safeguarding summary</h1>
      <p>Anonymous oversight summary only. No pupil content is included.</p>
      <ul>
        <li>Total flagged incidents: ${summary.totalFlaggedIncidents}</li>
        <li>High severity incidents: ${summary.highSeverityIncidents}</li>
        <li>Unique impacted users: ${summary.uniqueImpactedUsers}</li>
      </ul>
      <h2>Category breakdown</h2>
      ${htmlList(Object.entries(summary.categoryBreakdown).map(([label, count]) => `${label}: ${count}`))}
      <h2>Severity breakdown</h2>
      ${htmlList(Object.entries(summary.severityBreakdown).map(([label, count]) => `${label}: ${count}`))}
    </body></html>
  `;
}

function renderTeacherSummaryEmail(schoolName, summary) {
  return `
    <html><body>
      <h1>${schoolName} teacher safeguarding summary</h1>
      <p>Summary-only school safeguarding awareness. No raw student messages are included.</p>
      <ul>
        <li>Blocked/flagged searches: ${summary.blockedSearches}</li>
        <li>Medium or higher safeguarding incidents: ${summary.mediumOrHigherIncidents}</li>
        <li>Referral required: ${summary.referralRequired ? "Yes" : "No"}</li>
      </ul>
      <h2>Recurring risk patterns</h2>
      ${htmlList(summary.recurringRiskPatterns)}
      ${summary.referralRequired ? '<p><strong>Action:</strong> Refer safeguarding concerns to the DSL for detailed review.</p>' : ""}
    </body></html>
  `;
}

function createCsvAttachment(incidents) {
  const rows = [
    ["student_identifier", "filter_type", "severity", "action_taken", "timestamp_utc", "message_excerpt"],
    ...incidents.map((incident) => [incident.displayName, incident.filterType, incident.severity, incident.actionTaken, new Date(incident.timestamp).toISOString(), incident.userMessage.slice(0, 200)]),
  ];
  const csv = rows.map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(",")).join("\n");
  return {
    name: "safeguarding-incidents.csv",
    contentType: "text/csv",
    contentInBase64: Buffer.from(csv, "utf-8").toString("base64"),
  };
}

module.exports = {
  createCsvAttachment,
  renderDslIncidentEmail,
  renderKeywordWatchEmail,
  renderLeadershipSummaryEmail,
  renderTeacherSummaryEmail,
  renderUsageSummaryEmail,
};
