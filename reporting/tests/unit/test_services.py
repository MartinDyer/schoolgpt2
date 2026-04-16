from __future__ import annotations

import io
import json

import reporting.services as services


class FakeResponse:
    def __init__(self, payload):
        self.payload = payload

    def read(self):
        return json.dumps(self.payload).encode("utf-8")

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False


def _set_env(monkeypatch):
    monkeypatch.setenv('SQL_CONNECTION_STRING', 'Server=tcp:test.database.windows.net,1433;Database=schoolgpt;Uid=user;Pwd=pass;Encrypt=yes;TrustServerCertificate=no;')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('REPORTING_API_BASE', 'https://example.azurewebsites.net/api/reporting')
    monkeypatch.setenv('REPORTING_API_KEY', 'test-key')
    monkeypatch.setenv('DSL_EMAIL', 'dsl@example.com')
    monkeypatch.setenv('EMAIL_FROM', 'noreply@example.com')
    monkeypatch.setenv('EMAIL_PROVIDER', 'mock')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('REPORTING_INITIAL_WATERMARK', '2026-01-01T00:00:00Z')


def test_run_backend_report_posts_to_expected_endpoint(monkeypatch):
    _set_env(monkeypatch)
    services.get_settings.cache_clear()

    captured = {}

    def fake_urlopen(req, timeout=0):
        captured['url'] = req.full_url
        captured['method'] = req.get_method()
        captured['key'] = req.get_header('X-reporting-key')
        return FakeResponse({'ok': True, 'count': 3})

    monkeypatch.setattr(services.request, 'urlopen', fake_urlopen)

    assert services.run_dsl_daily_report() == 3
    assert captured['url'].endswith('/run/dsl-daily')
    assert captured['method'] == 'POST'
    assert captured['key'] == 'test-key'


def test_run_backend_report_raises_on_backend_failure(monkeypatch):
    _set_env(monkeypatch)
    services.get_settings.cache_clear()

    monkeypatch.setattr(services.request, 'urlopen', lambda req, timeout=0: FakeResponse({'ok': False, 'error': 'boom'}))

    try:
        services.run_usage_daily_report()
        assert False, 'Expected backend failure to raise'
    except RuntimeError as exc:
        assert 'Backend reporting endpoint failed' in str(exc)
