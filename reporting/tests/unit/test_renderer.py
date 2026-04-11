from __future__ import annotations

from datetime import datetime, timezone

from reporting.email.renderer import create_dsl_incident_csv_attachment, render_dsl_incident_email, render_leadership_summary_email, render_teacher_summary_email, render_usage_summary_email
from reporting.models import IncidentRecord, IncidentTrend, LeadershipSummary, TeacherSummary, UsageSummary


def test_render_dsl_email_contains_required_fields(monkeypatch):
    monkeypatch.setenv('SQL_CONNECTION_STRING', 'Driver=test')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('DSL_EMAIL', 'dsl@example.com')
    monkeypatch.setenv('EMAIL_FROM', 'noreply@example.com')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('REPORTING_INITIAL_WATERMARK', '2026-01-01T00:00:00Z')

    email = render_dsl_incident_email([
        IncidentRecord(
            incident_id='1',
            user_id='u1',
            display_name='Student A',
            user_type='Student',
            grade='8',
            session_id='s1',
            filter_type='SelfHarm',
            severity='high',
            action_taken='Blocked',
            user_message='Need help right now',
            timestamp=datetime(2026, 4, 11, tzinfo=timezone.utc),
        )
    ])

    assert 'Student A' in email.html_body
    assert 'SelfHarm' in email.html_body
    assert 'BST' in email.html_body or 'GMT' in email.html_body
    assert email.recipients == ('dsl@example.com',)


def test_usage_summary_contains_no_raw_prompt(monkeypatch):
    monkeypatch.setenv('SQL_CONNECTION_STRING', 'Driver=test')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('DSL_EMAIL', 'dsl@example.com')
    monkeypatch.setenv('SUMMARY_EMAILS', 'head@example.com')
    monkeypatch.setenv('EMAIL_FROM', 'noreply@example.com')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('REPORTING_INITIAL_WATERMARK', '2026-01-01T00:00:00Z')

    email = render_usage_summary_email([
        UsageSummary(
            usage_date=datetime(2026, 4, 11, tzinfo=timezone.utc),
            unique_users=2,
            unique_sessions=3,
            total_messages=12,
            average_tokens_per_message=100.0,
            total_tokens=1200,
        )
    ])

    assert 'how to hurt myself' not in email.html_body
    assert '00:00:00' not in email.html_body
    assert email.recipients == ('head@example.com',)


def test_render_leadership_summary_is_aggregate_only(monkeypatch):
    monkeypatch.setenv('SQL_CONNECTION_STRING', 'Server=tcp:test.database.windows.net,1433;Database=schoolgpt;Uid=user;Pwd=pass;Encrypt=yes;TrustServerCertificate=no;')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('DSL_EMAIL', 'dsl@example.com')
    monkeypatch.setenv('LEADERSHIP_EMAILS', 'leadership@example.com')
    monkeypatch.setenv('EMAIL_FROM', 'noreply@example.com')
    monkeypatch.setenv('EMAIL_PROVIDER', 'mock')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('REPORTING_INITIAL_WATERMARK', '2026-01-01T00:00:00Z')
    summary = LeadershipSummary(
        generated_at=datetime(2026, 4, 11, tzinfo=timezone.utc),
        total_flagged_incidents=3,
        high_severity_incidents=1,
        unique_impacted_users=2,
        category_breakdown=(IncidentTrend('SelfHarm', 2),),
        severity_breakdown=(IncidentTrend('high', 1),),
    )
    email = render_leadership_summary_email(summary)
    assert 'Student A' not in email.html_body
    assert email.recipients == ('leadership@example.com',)


def test_render_teacher_summary_contains_referral_not_raw_content(monkeypatch):
    monkeypatch.setenv('SQL_CONNECTION_STRING', 'Server=tcp:test.database.windows.net,1433;Database=schoolgpt;Uid=user;Pwd=pass;Encrypt=yes;TrustServerCertificate=no;')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('DSL_EMAIL', 'dsl@example.com')
    monkeypatch.setenv('TEACHER_SUMMARY_EMAILS', 'teacher@example.com')
    monkeypatch.setenv('EMAIL_FROM', 'noreply@example.com')
    monkeypatch.setenv('EMAIL_PROVIDER', 'mock')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('REPORTING_INITIAL_WATERMARK', '2026-01-01T00:00:00Z')
    summary = TeacherSummary(
        generated_at=datetime(2026, 4, 11, tzinfo=timezone.utc),
        blocked_searches=4,
        medium_or_higher_incidents=2,
        recurring_risk_patterns=('Repeated concern in SelfHarm (2 occurrences)',),
        referral_required=True,
    )
    email = render_teacher_summary_email(summary)
    assert 'Refer safeguarding concerns to the DSL' in email.html_body
    assert email.recipients == ('teacher@example.com',)


def test_create_dsl_incident_csv_attachment_contains_headers_and_rows():
    attachment = create_dsl_incident_csv_attachment([
        IncidentRecord(
            incident_id='1',
            user_id='u1',
            display_name='Student A',
            user_type='Student',
            grade='8',
            session_id='s1',
            filter_type='SelfHarm',
            severity='high',
            action_taken='Blocked',
            user_message='Need help right now',
            timestamp=datetime(2026, 4, 11, tzinfo=timezone.utc),
        )
    ])
    csv_text = attachment.content_bytes.decode('utf-8')
    assert attachment.name == 'safeguarding-incidents.csv'
    assert 'student_identifier,filter_type,severity' in csv_text
    assert 'Student A,SelfHarm,high' in csv_text
