from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


@dataclass(frozen=True)
class Settings:
    school_name: str
    school_timezone: str
    reporting_api_base: str
    reporting_api_key: str
    dsl_report_schedule: str
    usage_report_schedule: str
    keyword_report_schedule: str
    leadership_report_schedule: str
    teacher_summary_schedule: str
    retention_report_schedule: str

    @property
    def timezone(self) -> ZoneInfo:
        return ZoneInfo(self.school_timezone)

    @property
    def normalized_reporting_api_base(self) -> str:
        return self.reporting_api_base.rstrip("/")


def _require_env(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, default)
    if value is None or not value.strip():
        raise ValueError(f"{name} is required")
    return value


def _validate_timezone(value: str) -> str:
    try:
        ZoneInfo(value)
    except ZoneInfoNotFoundError as exc:
        raise ValueError(f"Invalid SCHOOL_TIMEZONE: {value}") from exc
    return value


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    school_timezone = _validate_timezone(_require_env("SCHOOL_TIMEZONE"))
    return Settings(
        school_name=_require_env("SCHOOL_NAME"),
        school_timezone=school_timezone,
        reporting_api_base=_require_env("REPORTING_API_BASE"),
        reporting_api_key=_require_env("REPORTING_API_KEY"),
        dsl_report_schedule=_require_env("DSL_REPORT_SCHEDULE"),
        usage_report_schedule=_require_env("USAGE_REPORT_SCHEDULE"),
        keyword_report_schedule=_require_env("KEYWORD_REPORT_SCHEDULE"),
        leadership_report_schedule=_require_env("LEADERSHIP_REPORT_SCHEDULE", "0 0 9 * * 1"),
        teacher_summary_schedule=_require_env("TEACHER_SUMMARY_SCHEDULE", "0 30 8 * * 1-5"),
        retention_report_schedule=_require_env("RETENTION_REPORT_SCHEDULE", "0 0 3 * * 0"),
    )
