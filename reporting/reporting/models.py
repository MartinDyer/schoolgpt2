from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import IntEnum


class SeverityLevel(IntEnum):
    low = 1
    medium = 2
    high = 3
    critical = 4

    @classmethod
    def from_value(cls, value: str | None) -> "SeverityLevel":
        normalized = (value or "medium").strip().lower()
        return {
            "low": cls.low,
            "medium": cls.medium,
            "high": cls.high,
            "critical": cls.critical,
        }.get(normalized, cls.medium)


@dataclass(frozen=True)
class IncidentRecord:
    incident_id: str
    user_id: str | None
    display_name: str
    user_type: str | None
    grade: str | None
    session_id: str | None
    filter_type: str
    severity: str
    action_taken: str
    user_message: str
    timestamp: datetime
    details: str | None = None

    @property
    def severity_level(self) -> SeverityLevel:
        return SeverityLevel.from_value(self.severity)


@dataclass(frozen=True)
class UsageSummary:
    usage_date: datetime
    unique_users: int
    unique_sessions: int
    total_messages: int
    average_tokens_per_message: float | None
    total_tokens: int | None


@dataclass(frozen=True)
class IncidentTrend:
    label: str
    count: int


@dataclass(frozen=True)
class LeadershipSummary:
    generated_at: datetime
    total_flagged_incidents: int
    high_severity_incidents: int
    unique_impacted_users: int
    category_breakdown: tuple[IncidentTrend, ...]
    severity_breakdown: tuple[IncidentTrend, ...]


@dataclass(frozen=True)
class TeacherSummary:
    generated_at: datetime
    blocked_searches: int
    medium_or_higher_incidents: int
    recurring_risk_patterns: tuple[str, ...]
    referral_required: bool


@dataclass(frozen=True)
class EmailAttachment:
    name: str
    content_type: str
    content_bytes: bytes


@dataclass(frozen=True)
class EmailMessage:
    subject: str
    html_body: str
    recipients: tuple[str, ...]
    tags: dict[str, str] = field(default_factory=dict)
    attachments: tuple[EmailAttachment, ...] = field(default_factory=tuple)
