from __future__ import annotations

from reporting.db.queries import apply_reporting_retention


class FakeCursor:
    def __init__(self):
        self.last_result = []
        self.rowcount = 0
        self.executed = []

    def execute(self, query, params=None):
        self.executed.append((query, params))
        if 'INFORMATION_SCHEMA.TABLES' in query:
            table_name = params[0]
            self.last_result = [(table_name,)]
        elif 'DELETE FROM dbo.AuditLog' in query:
            self.rowcount = 2
            self.last_result = []
        elif 'DELETE FROM dbo.ReportingAuditLog' in query:
            self.rowcount = 1
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


def test_apply_reporting_retention_returns_deleted_counts():
    connection = FakeConnection()
    deleted = apply_reporting_retention(connection, retention_days=90)
    assert deleted['AuditLog'] == 2
    assert deleted['ReportingAuditLog'] == 1
