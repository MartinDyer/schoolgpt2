from __future__ import annotations

import csv
from io import StringIO
from datetime import date, datetime, time, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from jinja2 import Environment, FileSystemLoader, select_autoescape

from reporting.models import EmailAttachment, EmailMessage, IncidentRecord, LeadershipSummary, TeacherSummary, UsageSummary
from reporting.runtime import get_settings


_env = Environment(
    loader=FileSystemLoader(str(Path(__file__).resolve().parent.parent / "templates")),
    autoescape=select_autoescape(["html", "xml"]),
)


def _format_local_time(value, timezone_name: str) -> str:
    tz = ZoneInfo(timezone_name)
    if isinstance(value, date) and not isinstance(value, datetime):
        value = datetime.combine(value, time.min, tzinfo=timezone.utc)
    elif value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(tz).strftime("%Y-%m-%d %H:%M:%S %Z")


def _format_local_date(value, timezone_name: str) -> str:
    tz = ZoneInfo(timezone_name)
    if isinstance(value, date) and not isinstance(value, datetime):
        return value.strftime("%Y-%m-%d")
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(tz).strftime("%Y-%m-%d")


_env.filters["localtime"] = _format_local_time
_env.filters["localdate"] = _format_local_date


def render_dsl_incident_email(incidents: list[IncidentRecord]) -> EmailMessage:
    settings = get_settings()
    template = _env.get_template("dsl_daily.html.j2")
    html_body = template.render(school_name=settings.school_name, incidents=incidents, school_timezone=settings.school_timezone)
    return EmailMessage(
        subject=f"{settings.school_name} safeguarding incidents",
        html_body=html_body,
        recipients=(settings.dsl_email,),
        tags={"report": "dsl_daily"},
    )


def create_dsl_incident_csv_attachment(incidents: list[IncidentRecord]) -> EmailAttachment:
    buffer = StringIO()
    writer = csv.writer(buffer)
    writer.writerow(["student_identifier", "filter_type", "severity", "action_taken", "timestamp_utc", "message_excerpt"])
    for incident in incidents:
        writer.writerow(
            [
                incident.display_name,
                incident.filter_type,
                incident.severity,
                incident.action_taken,
                incident.timestamp.isoformat(),
                incident.user_message[:200],
            ]
        )
    return EmailAttachment(
        name="safeguarding-incidents.csv",
        content_type="text/csv",
        content_bytes=buffer.getvalue().encode("utf-8"),
    )


def render_usage_summary_email(summaries: list[UsageSummary]) -> EmailMessage:
    settings = get_settings()
    recipients = tuple(email.strip() for email in settings.summary_emails.split(",") if email.strip())
    template = _env.get_template("usage_daily.html.j2")
    html_body = template.render(school_name=settings.school_name, summaries=summaries, school_timezone=settings.school_timezone)
    return EmailMessage(
        subject=f"{settings.school_name} usage summary",
        html_body=html_body,
        recipients=recipients,
        tags={"report": "usage_daily"},
    )


def render_keyword_watch_email(incidents: list[IncidentRecord], watch_terms: list[str]) -> EmailMessage:
    settings = get_settings()
    template = _env.get_template("keyword_watch.html.j2")
    html_body = template.render(
        school_name=settings.school_name,
        incidents=incidents,
        watch_terms=watch_terms,
        school_timezone=settings.school_timezone,
    )
    return EmailMessage(
        subject=f"{settings.school_name} keyword watch",
        html_body=html_body,
        recipients=(settings.dsl_email,),
        tags={"report": "keyword_watch"},
    )


def render_leadership_summary_email(summary: LeadershipSummary) -> EmailMessage:
    settings = get_settings()
    template = _env.get_template("leadership_summary.html.j2")
    html_body = template.render(school_name=settings.school_name, summary=summary, school_timezone=settings.school_timezone)
    return EmailMessage(
        subject=f"{settings.school_name} safeguarding leadership summary",
        html_body=html_body,
        recipients=settings.parsed_leadership_emails,
        tags={"report": "leadership_summary"},
    )


def render_teacher_summary_email(summary: TeacherSummary) -> EmailMessage:
    settings = get_settings()
    template = _env.get_template("teacher_summary.html.j2")
    html_body = template.render(school_name=settings.school_name, summary=summary, school_timezone=settings.school_timezone)
    return EmailMessage(
        subject=f"{settings.school_name} safeguarding summary for staff",
        html_body=html_body,
        recipients=settings.parsed_teacher_summary_emails,
        tags={"report": "teacher_summary"},
    )
