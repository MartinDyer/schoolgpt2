const { sql, sqlPool } = require("../db");

const severityOrder = { low: 1, medium: 2, high: 3, critical: 4 };

function severityMeetsThreshold(severity, minSeverity) {
  return (severityOrder[(severity || "medium").toLowerCase()] || 2) >= (severityOrder[(minSeverity || "medium").toLowerCase()] || 2);
}

function parseFlaggedDetail(detailJson, reason) {
  if (!detailJson) return { severity: "medium", filterType: reason || "content_filter", details: null };

  try {
    const parsed = JSON.parse(detailJson);
    if (parsed && typeof parsed === "object") {
      for (const [category, payload] of Object.entries(parsed)) {
        if (payload && typeof payload === "object" && payload.filtered) {
          return { severity: payload.severity || "medium", filterType: category, details: detailJson };
        }
      }
    }
  } catch {
    return { severity: "medium", filterType: reason || "content_filter", details: detailJson };
  }

  return { severity: "medium", filterType: reason || "content_filter", details: detailJson };
}

async function fetchFlaggedIncidents(sinceUtc, minSeverity = "medium") {
  const result = await sqlPool()
    .request()
    .input("sinceUtc", sql.DateTime2, sinceUtc)
    .query(`
      SELECT TOP 500 id, userId, sessionId, phase, originalPrompt, enhancedPrompt, reason, detail, createdAt
      FROM dbo.FlaggedMessages
      WHERE createdAt > @sinceUtc
      ORDER BY createdAt ASC
    `);

  return result.recordset
    .map((row) => {
      const parsed = parseFlaggedDetail(row.detail, row.reason);
      return {
        incidentId: String(row.id),
        userId: row.userId,
        displayName: row.userId || "Unknown User",
        sessionId: row.sessionId,
        phase: row.phase,
        filterType: parsed.filterType,
        severity: parsed.severity,
        actionTaken: row.phase || "Blocked",
        userMessage: row.originalPrompt || row.enhancedPrompt || "",
        timestamp: row.createdAt,
        details: parsed.details,
      };
    })
    .filter((item) => severityMeetsThreshold(item.severity, minSeverity));
}

async function fetchUsageSummaries(sinceUtc) {
  const result = await sqlPool()
    .request()
    .input("sinceUtc", sql.DateTime2, sinceUtc)
    .query(`
      SELECT CAST(updatedAt AS DATE) AS usageDate,
             COUNT(DISTINCT userId) AS uniqueUsers,
             COUNT(DISTINCT sessionId) AS uniqueSessions,
             SUM(messageCount) AS totalMessages,
             MAX(updatedAt) AS sourceHighWatermark
      FROM dbo.Chats
      WHERE updatedAt > @sinceUtc
      GROUP BY CAST(updatedAt AS DATE)
      ORDER BY usageDate DESC
    `);

  const summaries = result.recordset.map((row) => ({
    usageDate: row.usageDate,
    uniqueUsers: row.uniqueUsers,
    uniqueSessions: row.uniqueSessions,
    totalMessages: row.totalMessages,
    sourceHighWatermark: row.sourceHighWatermark,
  }));

  const sourceHighWatermark = summaries.reduce((latest, summary) => {
    if (!summary.sourceHighWatermark) {
      return latest;
    }

    if (!latest || summary.sourceHighWatermark > latest) {
      return summary.sourceHighWatermark;
    }

    return latest;
  }, null);

  return {
    summaries,
    sourceHighWatermark,
  };
}

async function fetchKeywordIncidents(sinceUtc, watchTerms) {
  const incidents = await fetchFlaggedIncidents(sinceUtc, "low");
  const loweredTerms = (watchTerms || []).map((term) => term.toLowerCase());
  return incidents.filter((incident) => loweredTerms.some((term) => incident.userMessage.toLowerCase().includes(term)));
}

async function fetchLeadershipSummary(sinceUtc) {
  const incidents = await fetchFlaggedIncidents(sinceUtc, "low");
  const categoryBreakdown = {};
  const severityBreakdown = {};
  const users = new Set();

  for (const incident of incidents) {
    categoryBreakdown[incident.filterType] = (categoryBreakdown[incident.filterType] || 0) + 1;
    severityBreakdown[incident.severity] = (severityBreakdown[incident.severity] || 0) + 1;
    if (incident.userId) {
      users.add(incident.userId);
    }
  }

  return {
    generatedAt: new Date().toISOString(),
    totalFlaggedIncidents: incidents.length,
    highSeverityIncidents: incidents.filter((incident) => severityMeetsThreshold(incident.severity, "high")).length,
    uniqueImpactedUsers: users.size,
    categoryBreakdown,
    severityBreakdown,
    sourceHighWatermark: incidents[incidents.length - 1]?.timestamp || null,
  };
}

async function fetchTeacherSummary(sinceUtc) {
  const incidents = await fetchFlaggedIncidents(sinceUtc, "low");
  const patternCounts = {};

  for (const incident of incidents) {
    patternCounts[incident.filterType] = (patternCounts[incident.filterType] || 0) + 1;
  }

  const recurringRiskPatterns = Object.entries(patternCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([label, count]) => `Repeated concern in ${label} (${count} occurrences)`);

  const mediumOrHigherIncidents = incidents.filter((incident) => severityMeetsThreshold(incident.severity, "medium")).length;
  return {
    generatedAt: new Date().toISOString(),
    blockedSearches: incidents.length,
    mediumOrHigherIncidents,
    recurringRiskPatterns,
    referralRequired: mediumOrHigherIncidents > 0,
    sourceHighWatermark: incidents[incidents.length - 1]?.timestamp || null,
  };
}

module.exports = {
  fetchFlaggedIncidents,
  fetchKeywordIncidents,
  fetchLeadershipSummary,
  fetchTeacherSummary,
  fetchUsageSummaries,
  parseFlaggedDetail,
  severityMeetsThreshold,
};
