from __future__ import annotations

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
    monkeypatch.setenv('REPORTING_API_BASE', 'https://example.azurewebsites.net/api/reporting')
    monkeypatch.setenv('REPORTING_API_KEY', 'test-key')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('LEADERSHIP_REPORT_SCHEDULE', '0 0 9 * * 1')
    monkeypatch.setenv('TEACHER_SUMMARY_SCHEDULE', '0 30 8 * * 1-5')
    monkeypatch.setenv('RETENTION_REPORT_SCHEDULE', '0 0 3 * * 0')


def test_usage_report_second_run_proxy_calls_backend(monkeypatch):
    _set_env(monkeypatch)
    services.get_settings.cache_clear()
    state = {'calls': 0}

    def fake_urlopen(req, timeout=0):
        state['calls'] += 1
        if state['calls'] == 1:
            return FakeResponse({'ok': True, 'count': 1})
        return FakeResponse({'ok': True, 'count': 0})

    monkeypatch.setattr(services.request, 'urlopen', fake_urlopen)

    assert services.run_usage_daily_report() == 1
    assert services.run_usage_daily_report() == 0
    assert state['calls'] == 2


def test_proxy_supports_retention_endpoint(monkeypatch):
    _set_env(monkeypatch)
    services.get_settings.cache_clear()
    captured = {}

    def fake_urlopen(req, timeout=0):
        captured['url'] = req.full_url
        return FakeResponse({'ok': True, 'report': 'retention', 'count': 7})

    monkeypatch.setattr(services.request, 'urlopen', fake_urlopen)

    assert services.run_reporting_retention() == 7
    assert captured['url'].endswith('/run/retention')
