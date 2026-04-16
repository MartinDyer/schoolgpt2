from __future__ import annotations

import os
from collections import OrderedDict
from datetime import datetime
from functools import lru_cache
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, Field, field_validator, model_validator


class Settings(BaseModel):
    sql_connection_string: str = Field(default="", alias="SQL_CONNECTION_STRING")
    school_name: str = Field(alias="SCHOOL_NAME")
    school_timezone: str = Field(alias="SCHOOL_TIMEZONE")
    dsl_email: str = Field(alias="DSL_EMAIL")
    summary_emails: str = Field(default="", alias="SUMMARY_EMAILS")
    leadership_emails: str = Field(default="", alias="LEADERSHIP_EMAILS")
    teacher_summary_emails: str = Field(default="", alias="TEACHER_SUMMARY_EMAILS")
    enable_csv_export: bool = Field(default=True, alias="ENABLE_CSV_EXPORT")
    csv_export_threshold: int = Field(default=10, alias="CSV_EXPORT_THRESHOLD")
    reporting_api_base: str = Field(default="", alias="REPORTING_API_BASE")
    reporting_api_key: str = Field(default="", alias="REPORTING_API_KEY")
    email_provider: str = Field(default="azure_communication_services", alias="EMAIL_PROVIDER")
    email_from: str = Field(alias="EMAIL_FROM")
    email_provider_api_key: str = Field(default="", alias="EMAIL_PROVIDER_API_KEY")
    acs_connection_string: str = Field(default="", alias="ACS_CONNECTION_STRING")
    dsl_report_schedule: str = Field(alias="DSL_REPORT_SCHEDULE")
    usage_report_schedule: str = Field(alias="USAGE_REPORT_SCHEDULE")
    keyword_report_schedule: str = Field(alias="KEYWORD_REPORT_SCHEDULE")
    leadership_report_schedule: str = Field(default="0 0 9 * * 1", alias="LEADERSHIP_REPORT_SCHEDULE")
    teacher_summary_schedule: str = Field(default="0 30 8 * * 1-5", alias="TEACHER_SUMMARY_SCHEDULE")
    retention_report_schedule: str = Field(default="0 0 3 * * 0", alias="RETENTION_REPORT_SCHEDULE")
    reporting_initial_watermark: datetime = Field(alias="REPORTING_INITIAL_WATERMARK")
    keyword_watch_terms: str = Field(default="", alias="KEYWORD_WATCH_TERMS")
    dsl_min_severity: str = Field(default="medium", alias="DSL_MIN_SEVERITY")
    reporting_audit_retention_days: int = Field(default=90, alias="REPORTING_AUDIT_RETENTION_DAYS")

    @field_validator("dsl_email")
    @classmethod
    def validate_dsl_email(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("DSL_EMAIL is required")
        return value

    @field_validator("school_timezone")
    @classmethod
    def validate_timezone(cls, value: str) -> str:
        try:
            ZoneInfo(value)
        except ZoneInfoNotFoundError as exc:
            raise ValueError(f"Invalid SCHOOL_TIMEZONE: {value}") from exc
        return value

    @field_validator("email_provider")
    @classmethod
    def validate_provider(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in {"mock", "azure_communication_services"}:
            raise ValueError(f"Unsupported EMAIL_PROVIDER: {value}")
        return normalized

    @model_validator(mode="after")
    def validate_provider_requirements(self):
        if self.email_provider == "azure_communication_services" and not self.acs_connection_string.strip():
            raise ValueError("ACS_CONNECTION_STRING is required when EMAIL_PROVIDER=azure_communication_services")
        if not self.reporting_api_base.strip():
            raise ValueError("REPORTING_API_BASE is required")
        if not self.reporting_api_key.strip():
            raise ValueError("REPORTING_API_KEY is required")
        return self

    @property
    def parsed_watch_terms(self) -> list[str]:
        return [term.strip() for term in self.keyword_watch_terms.split(",") if term.strip()]

    @property
    def parsed_leadership_emails(self) -> tuple[str, ...]:
        return tuple(email.strip() for email in self.leadership_emails.split(",") if email.strip())

    @property
    def parsed_teacher_summary_emails(self) -> tuple[str, ...]:
        return tuple(email.strip() for email in self.teacher_summary_emails.split(",") if email.strip())

    @property
    def timezone(self) -> ZoneInfo:
        return ZoneInfo(self.school_timezone)

    @property
    def normalized_reporting_api_base(self) -> str:
        return self.reporting_api_base.rstrip('/')


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings.model_validate(os.environ)
