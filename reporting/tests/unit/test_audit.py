from __future__ import annotations

from reporting.db.audit import ensure_reporting_audit_table, record_report_audit_event


class FakeCursor:
    def __init__(self, audit_log_exists: bool):
        self.audit_log_exists = audit_log_exists
        self.executed = []
        self.last_result = None

    def execute(self, query, params=None):
        self.executed.append((query, params))
        if 'INFORMATION_SCHEMA.TABLES' in query:
            self.last_result = [('AuditLog',)] if self.audit_log_exists else []
        else:
            self.last_result = []
        return self

    def fetchone(self):
        return self.last_result[0] if self.last_result else None


class FakeConnection:
    def __init__(self, audit_log_exists: bool):
        self.cursors = []
        self.audit_log_exists = audit_log_exists
        self.commit_count = 0

    def cursor(self):
        cursor = FakeCursor(audit_log_exists=self.audit_log_exists)
        self.cursors.append(cursor)
        return cursor

    def commit(self):
        self.commit_count += 1


def test_ensure_reporting_audit_table_uses_existing_auditlog():
    connection = FakeConnection(audit_log_exists=True)
    assert ensure_reporting_audit_table(connection) == 'AuditLog'


def test_ensure_reporting_audit_table_creates_fallback_when_missing():
    connection = FakeConnection(audit_log_exists=False)
    assert ensure_reporting_audit_table(connection) == 'ReportingAuditLog'
    assert connection.commit_count == 1


def test_record_report_audit_event_inserts_into_auditlog():
    connection = FakeConnection(audit_log_exists=True)
    record_report_audit_event(
        connection,
        report_name='dsl_daily_report',
        event_type='ReportExecution',
        event_description='DSL report completed successfully',
        additional_data={'incident_count': 2},
    )
    all_queries = [query for cursor in connection.cursors for query, _params in cursor.executed]
    assert any('INSERT INTO dbo.AuditLog' in query for query in all_queries)


def test_record_report_audit_event_inserts_into_fallback_table():
    connection = FakeConnection(audit_log_exists=False)
    record_report_audit_event(
        connection,
        report_name='usage_daily_report',
        event_type='ReportEmailDispatch',
        event_description='Usage summary email dispatched',
        recipients=('dsl@example.com',),
        reason_code='ScheduledReportDispatch',
        additional_data={'summary_count': 1},
    )
    all_queries = [query for cursor in connection.cursors for query, _params in cursor.executed]
    assert any('INSERT INTO dbo.ReportingAuditLog' in query for query in all_queries)
