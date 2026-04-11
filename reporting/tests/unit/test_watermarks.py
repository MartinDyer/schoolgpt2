from __future__ import annotations

from datetime import datetime, timezone

from reporting.db.watermarks import get_watermark, report_lock, update_watermark


class FakeCursor:
    def __init__(self):
        self.rows = {}
        self.last_result = None

    def execute(self, query, *params):
        normalized = params[0] if len(params) == 1 and isinstance(params[0], tuple) else params
        if 'sp_getapplock' in query:
            self.last_result = [(0,)]
            return self
        if 'sp_releaseapplock' in query:
            self.last_result = []
            return self
        if 'SELECT LastProcessedAt' in query:
            report_name = normalized[0]
            value = self.rows.get(report_name)
            self.last_result = [(value,)] if value else []
        elif 'INSERT INTO dbo.ReportingWatermarks' in query and 'MERGE' not in query:
            self.rows[normalized[0]] = normalized[1]
            self.last_result = []
        elif 'MERGE dbo.ReportingWatermarks' in query:
            self.rows[normalized[0]] = normalized[1]
            self.last_result = []
        else:
            self.last_result = []
        return self

    def fetchone(self):
        return self.last_result[0] if self.last_result else None


class FakeConnection:
    def __init__(self):
        self.cursor_instance = FakeCursor()
        self.commit_count = 0

    def cursor(self):
        return self.cursor_instance

    def commit(self):
        self.commit_count += 1


def test_get_watermark_initializes_when_missing():
    connection = FakeConnection()
    initial = datetime(2026, 1, 1, tzinfo=timezone.utc)
    watermark = get_watermark(connection, 'dsl_daily_report', initial)
    assert watermark == initial


def test_update_watermark_persists_new_value():
    connection = FakeConnection()
    new_value = datetime(2026, 4, 11, tzinfo=timezone.utc)
    update_watermark(connection, 'dsl_daily_report', new_value)
    assert connection.cursor_instance.rows['dsl_daily_report'] == new_value


def test_report_lock_acquires_successfully():
    connection = FakeConnection()
    with report_lock(connection, 'dsl_daily_report'):
        assert True
