from __future__ import annotations

from datetime import datetime, timezone

from reporting.models import EmailMessage, UsageSummary
from reporting import services


class FakeConnection:
    def __init__(self):
        self.closed = False

    def close(self):
        self.closed = True


class FakeContextManager:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        return self.connection

    def __exit__(self, exc_type, exc, tb):
        return False


def test_usage_report_second_run_sends_zero(monkeypatch):
    connection = FakeConnection()
    state = {
        'watermark': datetime(2026, 4, 10, tzinfo=timezone.utc),
        'send_count': 0,
    }

    monkeypatch.setenv('SQL_CONNECTION_STRING', 'Driver=test')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('DSL_EMAIL', 'dsl@example.com')
    monkeypatch.setenv('SUMMARY_EMAILS', 'summary@example.com')
    monkeypatch.setenv('EMAIL_PROVIDER', 'mock')
    monkeypatch.setenv('EMAIL_FROM', 'noreply@example.com')
    monkeypatch.setenv('ACS_CONNECTION_STRING', 'endpoint=https://example/;accesskey=test')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('REPORTING_INITIAL_WATERMARK', '2026-01-01T00:00:00Z')

    monkeypatch.setattr(services, 'get_db_connection', lambda: FakeContextManager(connection))
    monkeypatch.setattr(services, 'report_lock', lambda _connection, _name: FakeContextManager(connection))
    monkeypatch.setattr(services, 'get_watermark', lambda _connection, _name, _initial: state['watermark'])
    monkeypatch.setattr(services, 'record_report_audit_event', lambda *args, **kwargs: None)

    def fake_fetch_usage_summaries(_connection, since_utc):
        if since_utc >= datetime(2026, 4, 11, tzinfo=timezone.utc):
            return []
        return [
            UsageSummary(
                usage_date=datetime(2026, 4, 11, tzinfo=timezone.utc),
                unique_users=2,
                unique_sessions=3,
                total_messages=12,
                average_tokens_per_message=100.0,
                total_tokens=1200,
            )
        ]

    monkeypatch.setattr(services, 'fetch_usage_summaries', fake_fetch_usage_summaries)
    monkeypatch.setattr(services, 'render_usage_summary_email', lambda summaries: EmailMessage('usage', 'body', ('summary@example.com',)))

    class FakeSender:
        def send(self, message):
            state['send_count'] += 1

    monkeypatch.setattr(services, 'get_email_sender', lambda: FakeSender())
    monkeypatch.setattr(services, 'send_with_retry', lambda sender, message: sender.send(message))
    monkeypatch.setattr(services, 'update_watermark', lambda _connection, _name, new_value: state.__setitem__('watermark', new_value))

    assert services.run_usage_daily_report() == 1
    assert services.run_usage_daily_report() == 0
    assert state['send_count'] == 1
