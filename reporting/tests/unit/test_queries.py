from __future__ import annotations

from datetime import datetime, timezone

from reporting.db import queries
from reporting.models import SeverityLevel


class FakeCursor:
    def __init__(self, result_sets):
        self.result_sets = result_sets
        self.index = 0

    def execute(self, _query, *_params):
        self.current = self.result_sets[self.index]
        self.index += 1
        return self

    def fetchall(self):
        return self.current


class FakeConnection:
    def __init__(self, result_sets):
        self._cursor = FakeCursor(result_sets)

    def cursor(self):
        return self._cursor


def test_detect_reporting_schema_prefers_infra():
    connection = FakeConnection([[('Users',), ('ContentFilterViolations',), ('vw_ContentFilterReview',)]])
    assert queries.detect_reporting_schema(connection) == 'infra'


def test_fetch_runtime_incidents_parses_detail_json():
    created_at = datetime(2026, 4, 11, tzinfo=timezone.utc)
    result_sets = [
        [('FlaggedMessages',)],
        [(
            '1',
            'student-1',
            'session-1',
            'ANSWER',
            'how to hurt myself',
            None,
            'content_filter',
            '{"self_harm": {"filtered": true, "severity": "high"}}',
            created_at,
        )],
    ]
    connection = FakeConnection(result_sets)
    incidents = queries.fetch_dsl_incidents(connection, created_at.replace(year=2026, month=4, day=10), 'medium')
    assert len(incidents) == 1
    assert incidents[0].filter_type == 'self_harm'
    assert incidents[0].severity == 'high'


def test_fetch_usage_summaries_uses_strictly_newer_boundary_for_infra():
    created_at = datetime(2026, 4, 11, tzinfo=timezone.utc)
    result_sets = [
        [('Users',), ('ContentFilterViolations',)],
        [(created_at, 2, 3, 12, 100.0, 1200)],
    ]
    connection = FakeConnection(result_sets)
    summaries = queries.fetch_usage_summaries(connection, created_at)
    assert len(summaries) == 1


def test_fetch_teacher_summary_builds_referral_signal():
    created_at = datetime(2026, 4, 11, tzinfo=timezone.utc)
    result_sets = [
        [('Users',), ('ContentFilterViolations',)],
        [
            ('1', 'student-1', 'Student A', 'Student', '8', 'session-1', 'SelfHarm', 'high', 'Blocked', 'msg', created_at, None),
            ('2', 'student-2', 'Student B', 'Student', '9', 'session-2', 'Violence', 'medium', 'Blocked', 'msg', created_at, None),
        ],
    ]
    connection = FakeConnection(result_sets)
    summary = queries.fetch_teacher_summary(connection, created_at.replace(day=10))
    assert summary.blocked_searches == 2
    assert summary.referral_required is True


def test_fetch_leadership_summary_aggregates_without_identity_output():
    created_at = datetime(2026, 4, 11, tzinfo=timezone.utc)
    result_sets = [
        [('Users',), ('ContentFilterViolations',)],
        [
            ('1', 'student-1', 'Student A', 'Student', '8', 'session-1', 'SelfHarm', 'high', 'Blocked', 'msg', created_at, None),
            ('2', 'student-2', 'Student B', 'Student', '9', 'session-2', 'Violence', 'medium', 'Blocked', 'msg', created_at, None),
        ],
    ]
    connection = FakeConnection(result_sets)
    summary = queries.fetch_leadership_summary(connection, created_at.replace(day=10))
    assert summary.total_flagged_incidents == 2
    assert summary.high_severity_incidents == 1
