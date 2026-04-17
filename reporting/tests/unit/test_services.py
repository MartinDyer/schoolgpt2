from __future__ import annotations

import io
import json
from email.message import Message
from urllib import error

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
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('REPORTING_API_BASE', 'https://example.azurewebsites.net/api/reporting')
    monkeypatch.setenv('REPORTING_API_KEY', 'test-key')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('LEADERSHIP_REPORT_SCHEDULE', '0 0 9 * * 1')
    monkeypatch.setenv('TEACHER_SUMMARY_SCHEDULE', '0 30 8 * * 1-5')
    monkeypatch.setenv('RETENTION_REPORT_SCHEDULE', '0 0 3 * * 0')


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

    monkeypatch.setattr(
        services.request,
        'urlopen',
        lambda req, timeout=0: FakeResponse(
            {
                'ok': False,
                'error': {
                    'code': 'reporting_execution_failed',
                    'message': 'boom',
                    'report': 'usage-daily',
                    'retryable': True,
                    'requestId': 'req-123',
                },
            }
        ),
    )

    try:
        services.run_usage_daily_report()
        assert False, 'Expected backend failure to raise'
    except RuntimeError as exc:
        message = str(exc)
        assert 'Backend reporting endpoint failed for usage-daily' in message
        assert 'code=reporting_execution_failed' in message
        assert 'requestId=req-123' in message


def test_run_backend_report_raises_on_http_error_with_contract_payload(monkeypatch):
    _set_env(monkeypatch)
    services.get_settings.cache_clear()

    payload = json.dumps(
        {
            'ok': False,
            'error': {
                'code': 'reporting_unauthorized',
                'message': 'Unauthorized reporting request',
                'report': 'unknown',
                'retryable': False,
                'requestId': 'req-auth',
            },
        }
    ).encode('utf-8')

    def fake_urlopen(req, timeout=0):
        raise error.HTTPError(req.full_url, 401, 'Unauthorized', hdrs=Message(), fp=FakeResponseBytes(payload))

    monkeypatch.setattr(services.request, 'urlopen', fake_urlopen)

    try:
        services.run_dsl_daily_report()
        assert False, 'Expected HTTP error to raise'
    except RuntimeError as exc:
        message = str(exc)
        assert 'status=401' in message
        assert 'code=reporting_unauthorized' in message
        assert 'requestId=req-auth' in message


def test_run_report_job_rejects_unknown_job(monkeypatch):
    _set_env(monkeypatch)
    services.get_settings.cache_clear()

    try:
        services.run_report_job('not-a-report')
        assert False, 'Expected invalid job to raise'
    except ValueError as exc:
        assert 'Unsupported report job' in str(exc)


class FakeResponseBytes(io.BytesIO):
    def __init__(self, payload: bytes):
        super().__init__(payload)
