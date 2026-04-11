from __future__ import annotations

import logging

from reporting.db.audit import record_report_audit_event
from reporting.db.connection import get_db_connection
from reporting.db.queries import (
    apply_reporting_retention,
    fetch_dsl_incidents,
    fetch_keyword_incidents,
    fetch_leadership_summary,
    fetch_teacher_summary,
    fetch_usage_summaries,
)
from reporting.db.watermarks import get_watermark, report_lock, update_watermark
from reporting.email.renderer import (
    create_dsl_incident_csv_attachment,
    render_dsl_incident_email,
    render_keyword_watch_email,
    render_leadership_summary_email,
    render_teacher_summary_email,
    render_usage_summary_email,
)
from reporting.email.sender import get_email_sender, send_with_retry
from reporting.models import IncidentRecord
from reporting.runtime import get_settings


def run_dsl_daily_report() -> int:
    settings = get_settings()
    sender = get_email_sender()
    with get_db_connection() as connection:
        with report_lock(connection, "dsl_daily_report"):
            since = get_watermark(connection, "dsl_daily_report", settings.reporting_initial_watermark)
            incidents = fetch_dsl_incidents(connection, since_utc=since, min_severity=settings.dsl_min_severity)
            if not incidents:
                record_report_audit_event(
                    connection,
                    report_name="dsl_daily_report",
                    event_type="ReportExecution",
                    event_description="DSL daily report executed with no new incidents",
                    reason_code="ScheduledReportRun",
                    additional_data={"since": since, "incident_count": 0},
                )
                logging.info("No new DSL incidents since watermark", extra={"since": since.isoformat()})
                return 0
            message = render_dsl_incident_email(incidents)
            if settings.enable_csv_export and len(incidents) > settings.csv_export_threshold:
                message = type(message)(
                    subject=message.subject,
                    html_body=message.html_body,
                    recipients=message.recipients,
                    tags=message.tags,
                    attachments=(create_dsl_incident_csv_attachment(incidents),),
                )
            send_with_retry(sender, message)
            record_report_audit_event(
                connection,
                report_name="dsl_daily_report",
                event_type="ReportEmailDispatch",
                event_description="DSL safeguarding report email dispatched",
                reason_code="ScheduledReportDispatch",
                recipients=message.recipients,
                additional_data={"since": since, "incident_count": len(incidents)},
            )
            update_watermark(connection, "dsl_daily_report", _latest_incident_timestamp(incidents))
            record_report_audit_event(
                connection,
                report_name="dsl_daily_report",
                event_type="ReportExecution",
                event_description="DSL daily report completed successfully",
                reason_code="ScheduledReportRun",
                additional_data={"incident_count": len(incidents)},
            )
            logging.info("DSL report watermark advanced", extra={"incident_count": len(incidents)})
            return len(incidents)


def run_usage_daily_report() -> int:
    settings = get_settings()
    sender = get_email_sender()
    with get_db_connection() as connection:
        with report_lock(connection, "usage_daily_report"):
            since = get_watermark(connection, "usage_daily_report", settings.reporting_initial_watermark)
            summaries = fetch_usage_summaries(connection, since_utc=since)
            if not summaries:
                record_report_audit_event(
                    connection,
                    report_name="usage_daily_report",
                    event_type="ReportExecution",
                    event_description="Usage report executed with no new aggregate data",
                    reason_code="ScheduledReportRun",
                    additional_data={"since": since, "summary_count": 0},
                )
                logging.info("No new usage summaries since watermark", extra={"since": since.isoformat()})
                return 0
            message = render_usage_summary_email(summaries)
            if not message.recipients:
                record_report_audit_event(
                    connection,
                    report_name="usage_daily_report",
                    event_type="ReportExecution",
                    event_description="Usage summary skipped because no recipients are configured",
                    severity="Warning",
                    reason_code="MissingRecipients",
                    additional_data={"summary_count": len(summaries)},
                )
                logging.info("Usage summary recipients not configured; skipping send")
                return 0
            send_with_retry(sender, message)
            record_report_audit_event(
                connection,
                report_name="usage_daily_report",
                event_type="ReportEmailDispatch",
                event_description="Usage summary report email dispatched",
                reason_code="ScheduledReportDispatch",
                recipients=message.recipients,
                additional_data={"summary_count": len(summaries)},
            )
            update_watermark(connection, "usage_daily_report", max(summary.usage_date for summary in summaries))
            record_report_audit_event(
                connection,
                report_name="usage_daily_report",
                event_type="ReportExecution",
                event_description="Usage summary report completed successfully",
                reason_code="ScheduledReportRun",
                additional_data={"summary_count": len(summaries)},
            )
            logging.info("Usage report watermark advanced", extra={"summary_count": len(summaries)})
            return len(summaries)


def run_keyword_watch_report() -> int:
    settings = get_settings()
    sender = get_email_sender()
    with get_db_connection() as connection:
        with report_lock(connection, "dsl_keyword_watch_report"):
            since = get_watermark(connection, "dsl_keyword_watch_report", settings.reporting_initial_watermark)
            incidents = fetch_keyword_incidents(connection, since_utc=since, watch_terms=settings.parsed_watch_terms)
            if not incidents:
                record_report_audit_event(
                    connection,
                    report_name="dsl_keyword_watch_report",
                    event_type="ReportExecution",
                    event_description="Keyword-watch report executed with no matching incidents",
                    reason_code="ScheduledReportRun",
                    additional_data={"since": since, "incident_count": 0, "watch_terms": settings.parsed_watch_terms},
                )
                logging.info("No keyword-watch incidents since watermark", extra={"since": since.isoformat()})
                return 0
            message = render_keyword_watch_email(incidents, settings.parsed_watch_terms)
            send_with_retry(sender, message)
            record_report_audit_event(
                connection,
                report_name="dsl_keyword_watch_report",
                event_type="ReportEmailDispatch",
                event_description="Keyword-watch report email dispatched",
                reason_code="ScheduledReportDispatch",
                recipients=message.recipients,
                additional_data={"incident_count": len(incidents), "watch_terms": settings.parsed_watch_terms},
            )
            update_watermark(connection, "dsl_keyword_watch_report", _latest_incident_timestamp(incidents))
            record_report_audit_event(
                connection,
                report_name="dsl_keyword_watch_report",
                event_type="ReportExecution",
                event_description="Keyword-watch report completed successfully",
                reason_code="ScheduledReportRun",
                additional_data={"incident_count": len(incidents), "watch_terms": settings.parsed_watch_terms},
            )
            logging.info("Keyword watch watermark advanced", extra={"incident_count": len(incidents)})
            return len(incidents)


def run_leadership_summary_report() -> int:
    settings = get_settings()
    sender = get_email_sender()
    with get_db_connection() as connection:
        with report_lock(connection, "leadership_summary_report"):
            since = get_watermark(connection, "leadership_summary_report", settings.reporting_initial_watermark)
            summary = fetch_leadership_summary(connection, since_utc=since)
            message = render_leadership_summary_email(summary)
            if not message.recipients:
                record_report_audit_event(
                    connection,
                    report_name="leadership_summary_report",
                    event_type="ReportExecution",
                    event_description="Leadership summary skipped because no recipients are configured",
                    severity="Warning",
                    reason_code="MissingRecipients",
                    additional_data={"total_flagged_incidents": summary.total_flagged_incidents},
                )
                return 0
            send_with_retry(sender, message)
            record_report_audit_event(
                connection,
                report_name="leadership_summary_report",
                event_type="ReportEmailDispatch",
                event_description="Leadership anonymised summary email dispatched",
                reason_code="ScheduledReportDispatch",
                recipients=message.recipients,
                additional_data={
                    "total_flagged_incidents": summary.total_flagged_incidents,
                    "high_severity_incidents": summary.high_severity_incidents,
                },
            )
            update_watermark(connection, "leadership_summary_report", summary.generated_at)
            record_report_audit_event(
                connection,
                report_name="leadership_summary_report",
                event_type="ReportExecution",
                event_description="Leadership summary report completed successfully",
                reason_code="ScheduledReportRun",
                additional_data={"total_flagged_incidents": summary.total_flagged_incidents},
            )
            return summary.total_flagged_incidents


def run_teacher_summary_report() -> int:
    settings = get_settings()
    sender = get_email_sender()
    with get_db_connection() as connection:
        with report_lock(connection, "teacher_summary_report"):
            since = get_watermark(connection, "teacher_summary_report", settings.reporting_initial_watermark)
            summary = fetch_teacher_summary(connection, since_utc=since)
            message = render_teacher_summary_email(summary)
            if not message.recipients:
                record_report_audit_event(
                    connection,
                    report_name="teacher_summary_report",
                    event_type="ReportExecution",
                    event_description="Teacher summary skipped because no recipients are configured",
                    severity="Warning",
                    reason_code="MissingRecipients",
                    additional_data={"blocked_searches": summary.blocked_searches},
                )
                return 0
            send_with_retry(sender, message)
            record_report_audit_event(
                connection,
                report_name="teacher_summary_report",
                event_type="ReportEmailDispatch",
                event_description="Teacher summary email dispatched",
                reason_code="ScheduledReportDispatch",
                recipients=message.recipients,
                additional_data={
                    "blocked_searches": summary.blocked_searches,
                    "referral_required": summary.referral_required,
                },
            )
            update_watermark(connection, "teacher_summary_report", summary.generated_at)
            record_report_audit_event(
                connection,
                report_name="teacher_summary_report",
                event_type="ReportExecution",
                event_description="Teacher summary report completed successfully",
                reason_code="ScheduledReportRun",
                additional_data={"blocked_searches": summary.blocked_searches},
            )
            return summary.blocked_searches


def run_reporting_retention() -> int:
    settings = get_settings()
    with get_db_connection() as connection:
        with report_lock(connection, "reporting_retention"):
            deleted = apply_reporting_retention(connection, settings.reporting_audit_retention_days)
            record_report_audit_event(
                connection,
                report_name="reporting_retention",
                event_type="RetentionExecution",
                event_description="Reporting retention policy applied",
                reason_code="RetentionCleanup",
                additional_data={"deleted": deleted, "retention_days": settings.reporting_audit_retention_days},
            )
            return sum(deleted.values())


def _latest_incident_timestamp(incidents: list[IncidentRecord]):
    return max(incident.timestamp for incident in incidents)
