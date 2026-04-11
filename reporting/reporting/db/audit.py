from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4


def ensure_reporting_audit_table(connection: Any) -> str:
    cursor = connection.cursor()
    audit_log_exists = cursor.execute(
        "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = %s",
        ("AuditLog",),
    ).fetchone()
    if audit_log_exists:
        return "AuditLog"

    cursor.execute(
        """
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReportingAuditLog]') AND type in (N'U'))
        BEGIN
          CREATE TABLE [dbo].[ReportingAuditLog] (
            [AuditId] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            [ReportName] NVARCHAR(100) NOT NULL,
            [EventType] NVARCHAR(100) NOT NULL,
            [EventDescription] NVARCHAR(MAX) NOT NULL,
            [Severity] NVARCHAR(20) NOT NULL DEFAULT 'Info',
            [ReasonCode] NVARCHAR(100) NULL,
            [Recipients] NVARCHAR(MAX) NULL,
            [AdditionalData] NVARCHAR(MAX) NULL,
            [Timestamp] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
            [Source] NVARCHAR(100) NOT NULL DEFAULT 'SchoolGPT.Reporting'
          );
        END
        """
    )
    connection.commit()
    return "ReportingAuditLog"


def record_report_audit_event(
    connection: Any,
    report_name: str,
    event_type: str,
    event_description: str,
    severity: str = "Info",
    reason_code: str | None = None,
    recipients: tuple[str, ...] | None = None,
    additional_data: dict[str, Any] | None = None,
) -> None:
    table_name = ensure_reporting_audit_table(connection)
    additional_json = json.dumps(additional_data or {}, default=_json_default)
    recipients_value = ",".join(recipients or ())

    cursor = connection.cursor()
    if table_name == "AuditLog":
        cursor.execute(
            """
            INSERT INTO dbo.AuditLog
            (EventType, EventDescription, Severity, Source, AdditionalData, Timestamp)
            VALUES (%s, %s, %s, %s, %s, SYSUTCDATETIME())
            """,
            (
                event_type,
                event_description,
                severity,
                "SchoolGPT.Reporting",
                additional_json,
            ),
        )
    else:
        cursor.execute(
            """
            INSERT INTO dbo.ReportingAuditLog
            (AuditId, ReportName, EventType, EventDescription, Severity, ReasonCode, Recipients, AdditionalData, Timestamp, Source)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, SYSUTCDATETIME(), %s)
            """,
            (
                str(uuid4()),
                report_name,
                event_type,
                event_description,
                severity,
                reason_code,
                recipients_value,
                additional_json,
                "SchoolGPT.Reporting",
            ),
        )
    connection.commit()


def _json_default(value: Any):
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.isoformat()
    return str(value)
