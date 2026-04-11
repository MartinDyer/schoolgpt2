from __future__ import annotations

import sys
from types import SimpleNamespace

from reporting.db.connection import get_db_connection


class FakeConnection:
    def __init__(self):
        self.autocommit = None
        self.closed = False

    def setautocommit(self, value):
        self.autocommit = value

    def close(self):
        self.closed = True


def test_get_db_connection_uses_mssql_python(monkeypatch):
    fake_connection = FakeConnection()
    captured = {}

    monkeypatch.setenv('SQL_CONNECTION_STRING', 'Server=tcp:test.database.windows.net,1433;Database=schoolgpt;Uid=user;Pwd=pass;Encrypt=yes;TrustServerCertificate=no;')
    monkeypatch.setenv('SCHOOL_NAME', 'Example School')
    monkeypatch.setenv('SCHOOL_TIMEZONE', 'Europe/London')
    monkeypatch.setenv('DSL_EMAIL', 'dsl@example.com')
    monkeypatch.setenv('EMAIL_FROM', 'noreply@example.com')
    monkeypatch.setenv('EMAIL_PROVIDER', 'mock')
    monkeypatch.setenv('DSL_REPORT_SCHEDULE', '0 0 7 * * *')
    monkeypatch.setenv('USAGE_REPORT_SCHEDULE', '0 0 8 * * *')
    monkeypatch.setenv('KEYWORD_REPORT_SCHEDULE', '0 0 7 * * 1')
    monkeypatch.setenv('REPORTING_INITIAL_WATERMARK', '2026-01-01T00:00:00Z')

    def fake_connect(**kwargs):
        captured.update(kwargs)
        return fake_connection

    monkeypatch.setitem(sys.modules, 'pytds', SimpleNamespace(connect=fake_connect))

    with get_db_connection(autocommit=True) as connection:
        assert connection is fake_connection

    assert captured['autocommit'] is True
    assert captured['server'] == 'test.database.windows.net'
    assert fake_connection.closed is True
