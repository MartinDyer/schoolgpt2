from __future__ import annotations

from datetime import datetime, timezone

from reporting.models import IncidentRecord
from reporting.services import _latest_incident_timestamp


def test_latest_incident_timestamp_returns_max():
    older = IncidentRecord(
        incident_id='1',
        user_id='u1',
        display_name='Student A',
        user_type='Student',
        grade='8',
        session_id='s1',
        filter_type='SelfHarm',
        severity='medium',
        action_taken='Blocked',
        user_message='help',
        timestamp=datetime(2026, 4, 10, tzinfo=timezone.utc),
    )
    newer = IncidentRecord(
        incident_id='2',
        user_id='u2',
        display_name='Student B',
        user_type='Student',
        grade='9',
        session_id='s2',
        filter_type='Violence',
        severity='high',
        action_taken='Blocked',
        user_message='fight',
        timestamp=datetime(2026, 4, 11, tzinfo=timezone.utc),
    )
    assert _latest_incident_timestamp([older, newer]) == newer.timestamp
