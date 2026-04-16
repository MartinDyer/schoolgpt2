from __future__ import annotations

import json
from datetime import datetime
from typing import Any

from reporting.models import IncidentRecord, IncidentTrend, LeadershipSummary, SeverityLevel, TeacherSummary, UsageSummary


PREFERRED_SCHEMA_CHECK = """
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('Users', 'ContentFilterViolations', 'FlaggedMessages')
UNION ALL
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME IN ('vw_ContentFilterReview', 'vw_DailyUsageStats')
"""


def detect_reporting_schema(connection: Any) -> str:
    cursor = connection.cursor()
    rows = cursor.execute(PREFERRED_SCHEMA_CHECK).fetchall()
    available = {row[0] for row in rows}
    if {"ContentFilterViolations", "Users"}.issubset(available):
        return "infra"
    if "FlaggedMessages" in available:
        return "runtime"
    raise RuntimeError("No supported reporting schema found")


def detect_incident_reporting_schema(connection: Any) -> str:
    cursor = connection.cursor()
    rows = cursor.execute(PREFERRED_SCHEMA_CHECK).fetchall()
    available = {row[0] for row in rows}
    if "FlaggedMessages" in available:
        return "runtime"
    raise RuntimeError("FlaggedMessages table is required for safeguarding incident reporting")


def fetch_role_counts(connection: Any) -> list[tuple[str, int]]:
    cursor = connection.cursor()
    rows = cursor.execute(
        "SELECT UserType, COUNT(*) FROM dbo.Users GROUP BY UserType ORDER BY UserType"
    ).fetchall()
    return [(row[0], row[1]) for row in rows]


def fetch_dsl_incidents(connection: Any, since_utc: datetime, min_severity: str) -> list[IncidentRecord]:
    detect_incident_reporting_schema(connection)
    return _fetch_runtime_incidents(connection, since_utc, min_severity)


def fetch_usage_summaries(connection: Any, since_utc: datetime) -> list[UsageSummary]:
    schema = detect_reporting_schema(connection)
    cursor = connection.cursor()
    if schema == "infra":
        rows = cursor.execute(
            """
            SELECT UsageDate, UniqueUsers, UniqueSessions, TotalMessages, AvgTokensPerMessage, TotalTokens
            FROM dbo.vw_DailyUsageStats
            WHERE UsageDate > CAST(%s AS DATE)
            ORDER BY UsageDate DESC
            """,
            (since_utc,),
        ).fetchall()
    else:
        rows = cursor.execute(
            """
            SELECT
                CAST(updatedAt AS DATE) AS UsageDate,
                COUNT(DISTINCT userId) AS UniqueUsers,
                COUNT(DISTINCT sessionId) AS UniqueSessions,
                SUM(messageCount) AS TotalMessages,
                NULL AS AvgTokensPerMessage,
                NULL AS TotalTokens
            FROM dbo.Chats
            WHERE updatedAt > %s
            GROUP BY CAST(updatedAt AS DATE)
            ORDER BY UsageDate DESC
            """,
            (since_utc,),
        ).fetchall()
    return [
        UsageSummary(
            usage_date=row[0],
            unique_users=row[1],
            unique_sessions=row[2],
            total_messages=row[3],
            average_tokens_per_message=float(row[4]) if row[4] is not None else None,
            total_tokens=row[5],
        )
        for row in rows
    ]


def fetch_keyword_incidents(connection: Any, since_utc: datetime, watch_terms: list[str]) -> list[IncidentRecord]:
    incidents = fetch_dsl_incidents(connection, since_utc, min_severity="low")
    lowered_terms = [term.lower() for term in watch_terms if term.strip()]
    return [
        incident
        for incident in incidents
        if any(term in incident.user_message.lower() for term in lowered_terms)
    ]


def fetch_leadership_summary(connection: Any, since_utc: datetime) -> LeadershipSummary:
    incidents = fetch_dsl_incidents(connection, since_utc=since_utc, min_severity="low")
    category_counts: dict[str, int] = {}
    severity_counts: dict[str, int] = {}
    impacted_users = {incident.user_id for incident in incidents if incident.user_id}

    for incident in incidents:
        category_counts[incident.filter_type] = category_counts.get(incident.filter_type, 0) + 1
        severity_counts[incident.severity] = severity_counts.get(incident.severity, 0) + 1

    return LeadershipSummary(
        generated_at=datetime.utcnow(),
        total_flagged_incidents=len(incidents),
        high_severity_incidents=sum(1 for incident in incidents if incident.severity_level >= SeverityLevel.high),
        unique_impacted_users=len(impacted_users),
        category_breakdown=tuple(IncidentTrend(label=key, count=value) for key, value in sorted(category_counts.items())),
        severity_breakdown=tuple(IncidentTrend(label=key, count=value) for key, value in sorted(severity_counts.items())),
    )


def fetch_teacher_summary(connection: Any, since_utc: datetime) -> TeacherSummary:
    incidents = fetch_dsl_incidents(connection, since_utc=since_utc, min_severity="low")
    pattern_counts: dict[str, int] = {}
    for incident in incidents:
        pattern_counts[incident.filter_type] = pattern_counts.get(incident.filter_type, 0) + 1

    recurring_patterns = tuple(
        f"Repeated concern in {label} ({count} occurrences)"
        for label, count in sorted(pattern_counts.items(), key=lambda item: item[1], reverse=True)
        if count >= 1
    )[:3]

    medium_or_higher = sum(1 for incident in incidents if incident.severity_level >= SeverityLevel.medium)
    return TeacherSummary(
        generated_at=datetime.utcnow(),
        blocked_searches=len(incidents),
        medium_or_higher_incidents=medium_or_higher,
        recurring_risk_patterns=recurring_patterns,
        referral_required=medium_or_higher > 0,
    )


def apply_reporting_retention(connection: Any, retention_days: int) -> dict[str, int]:
    cursor = connection.cursor()
    audit_exists = cursor.execute(
        "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = %s",
        ("AuditLog",),
    ).fetchone()
    fallback_exists = cursor.execute(
        "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = %s",
        ("ReportingAuditLog",),
    ).fetchone()

    deleted = {"AuditLog": 0, "ReportingAuditLog": 0}
    if audit_exists:
        cursor.execute(
            "DELETE FROM dbo.AuditLog WHERE Source = %s AND Timestamp < DATEADD(day, -%s, SYSUTCDATETIME())",
            ("SchoolGPT.Reporting", retention_days),
        )
        deleted["AuditLog"] = int(getattr(cursor, "rowcount", 0) or 0)
    if fallback_exists:
        cursor.execute(
            "DELETE FROM dbo.ReportingAuditLog WHERE Timestamp < DATEADD(day, -%s, SYSUTCDATETIME())",
            (retention_days,),
        )
        deleted["ReportingAuditLog"] = int(getattr(cursor, "rowcount", 0) or 0)
    connection.commit()
    return deleted


def _fetch_infra_incidents(connection: Any, since_utc: datetime, min_severity: str) -> list[IncidentRecord]:
    threshold = SeverityLevel.from_value(min_severity)
    cursor = connection.cursor()
    rows = cursor.execute(
        """
        SELECT
            cfv.ViolationId,
            CAST(cfv.UserId AS NVARCHAR(64)),
            u.DisplayName,
            u.UserType,
            u.Grade,
            CAST(cfv.SessionId AS NVARCHAR(64)),
            cfv.FilterType,
            cfv.Severity,
            cfv.ActionTaken,
            cfv.UserMessage,
            cfv.Timestamp,
            cfv.FilterResponse
        FROM dbo.ContentFilterViolations cfv
        LEFT JOIN dbo.Users u ON cfv.UserId = u.UserId
        WHERE cfv.Timestamp > %s
        ORDER BY cfv.Timestamp ASC
        """,
        (since_utc,),
    ).fetchall()
    incidents = [
        IncidentRecord(
            incident_id=str(row[0]),
            user_id=row[1],
            display_name=row[2] or f"Unknown User ({row[1] or 'n/a'})",
            user_type=row[3],
            grade=row[4],
            session_id=row[5],
            filter_type=row[6],
            severity=row[7],
            action_taken=row[8],
            user_message=row[9],
            timestamp=row[10],
            details=row[11],
        )
        for row in rows
    ]
    return [incident for incident in incidents if incident.severity_level >= threshold]


def _fetch_runtime_incidents(connection: Any, since_utc: datetime, min_severity: str) -> list[IncidentRecord]:
    threshold = SeverityLevel.from_value(min_severity)
    cursor = connection.cursor()
    rows = cursor.execute(
        """
        SELECT id, userId, sessionId, phase, originalPrompt, enhancedPrompt, reason, detail, createdAt
        FROM dbo.FlaggedMessages
        WHERE createdAt > %s
        ORDER BY createdAt ASC
        """,
        (since_utc,),
    ).fetchall()
    incidents: list[IncidentRecord] = []
    for row in rows:
        severity, filter_type, details = _parse_runtime_detail(row[7], row[6])
        incident = IncidentRecord(
            incident_id=str(row[0]),
            user_id=row[1],
            display_name=row[1] or "Unknown User",
            user_type=None,
            grade=None,
            session_id=row[2],
            filter_type=filter_type,
            severity=severity,
            action_taken=row[3] or "Logged",
            user_message=row[4] or row[5] or "",
            timestamp=row[8],
            details=details,
        )
        if incident.severity_level >= threshold:
            incidents.append(incident)
    return incidents


def _parse_runtime_detail(detail_json: str | None, reason: str | None) -> tuple[str, str, str | None]:
    if not detail_json:
        return ("medium", reason or "content_filter", None)
    try:
        parsed = json.loads(detail_json)
    except json.JSONDecodeError:
        return ("medium", reason or "content_filter", detail_json)
    if isinstance(parsed, dict):
        for category, payload in parsed.items():
            if isinstance(payload, dict) and payload.get("filtered"):
                severity = payload.get("severity", "medium")
                return (severity, category, detail_json)
    return ("medium", reason or "content_filter", detail_json)
