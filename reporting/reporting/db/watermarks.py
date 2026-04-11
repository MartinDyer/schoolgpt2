from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timezone
from typing import Any


def ensure_watermark_table(connection: Any) -> None:
    cursor = connection.cursor()
    cursor.execute(
        """
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReportingWatermarks]') AND type in (N'U'))
        BEGIN
          CREATE TABLE [dbo].[ReportingWatermarks] (
            [ReportName] NVARCHAR(100) NOT NULL PRIMARY KEY,
            [LastProcessedAt] DATETIME2 NOT NULL,
            [UpdatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
          );
        END
        """
    )
    connection.commit()


@contextmanager
def report_lock(connection: Any, report_name: str):
    yield


def get_watermark(connection: Any, report_name: str, initial_value: datetime) -> datetime:
    ensure_watermark_table(connection)
    cursor = connection.cursor()
    row = cursor.execute(
        "SELECT LastProcessedAt FROM dbo.ReportingWatermarks WHERE ReportName = %s",
        (report_name,),
    ).fetchone()
    if row:
        return _coerce_utc(row[0])
    cursor.execute(
        "INSERT INTO dbo.ReportingWatermarks (ReportName, LastProcessedAt) VALUES (%s, %s)",
        (report_name, initial_value),
    )
    connection.commit()
    return _coerce_utc(initial_value)


def update_watermark(connection: Any, report_name: str, new_value: datetime) -> None:
    cursor = connection.cursor()
    cursor.execute(
        """
        MERGE dbo.ReportingWatermarks AS target
        USING (SELECT %s AS ReportName, %s AS LastProcessedAt) AS source
        ON target.ReportName = source.ReportName
        WHEN MATCHED THEN
          UPDATE SET LastProcessedAt = source.LastProcessedAt, UpdatedAt = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
          INSERT (ReportName, LastProcessedAt) VALUES (source.ReportName, source.LastProcessedAt);
        """,
        (report_name, new_value),
    )
    connection.commit()


def _coerce_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)
