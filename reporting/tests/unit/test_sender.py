from __future__ import annotations

import pytest

from reporting.email.sender import EmailSender, get_email_sender, send_with_retry
from reporting.models import EmailMessage


class FlakySender(EmailSender):
    def __init__(self, fail_count: int) -> None:
        self.fail_count = fail_count
        self.calls = 0

    def send(self, message: EmailMessage) -> None:
        self.calls += 1
        if self.calls <= self.fail_count:
            raise RuntimeError('send failed')


def test_send_with_retry_succeeds_after_retry(monkeypatch):
    sender = FlakySender(fail_count=1)
    monkeypatch.setattr('reporting.email.sender.time.sleep', lambda _seconds: None)
    send_with_retry(sender, EmailMessage(subject='x', html_body='y', recipients=('a@example.com',)))
    assert sender.calls == 2


def test_send_with_retry_raises_after_exhaustion(monkeypatch):
    sender = FlakySender(fail_count=3)
    monkeypatch.setattr('reporting.email.sender.time.sleep', lambda _seconds: None)
    with pytest.raises(RuntimeError):
        send_with_retry(sender, EmailMessage(subject='x', html_body='y', recipients=('a@example.com',)), max_attempts=3)


def test_get_email_sender_supports_acs(monkeypatch):
    monkeypatch.setenv('SQL_CONNECTION_STRING', 'Driver=test')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('DSL_EMAIL', 'dsl@example.com')
    monkeypatch.setenv('EMAIL_FROM', 'noreply@example.com')
    monkeypatch.setenv('EMAIL_PROVIDER', 'azure_communication_services')
    monkeypatch.setenv('ACS_CONNECTION_STRING', 'endpoint=https://example/;accesskey=test')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('REPORTING_INITIAL_WATERMARK', '2026-01-01T00:00:00Z')

    sender = get_email_sender()
    assert sender.__class__.__name__ == 'AzureCommunicationServicesEmailSender'
