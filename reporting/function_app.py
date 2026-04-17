from __future__ import annotations

import importlib
import logging
from types import SimpleNamespace

from reporting.runtime import get_settings
from reporting.services import run_report_job


def _load_functions_module():
    try:
        return importlib.import_module("azure.functions")
    except ImportError:
        class TimerRequest:  # pragma: no cover - fallback for local tooling only
            pass

        class FunctionApp:  # pragma: no cover - fallback for local tooling only
            def timer_trigger(self, **_kwargs):
                def decorator(func):
                    return func

                return decorator

        return SimpleNamespace(FunctionApp=FunctionApp, TimerRequest=TimerRequest)


func = _load_functions_module()

app = func.FunctionApp()


def _log_placeholder(report_name: str) -> None:
    settings = get_settings()
    logging.info(
        "Reporting function placeholder invoked",
        extra={
            "report_name": report_name,
            "school_name": settings.school_name,
            "timezone": settings.school_timezone,
        },
    )


@app.timer_trigger(schedule="%DSL_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def dsl_daily_report(timer) -> None:
    _log_placeholder("dsl_daily_report")
    count = run_report_job("dsl-daily")
    logging.info("DSL daily report complete", extra={"incident_count": count})


@app.timer_trigger(schedule="%USAGE_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def usage_daily_report(timer) -> None:
    _log_placeholder("usage_daily_report")
    count = run_report_job("usage-daily")
    logging.info("Usage daily report complete", extra={"summary_count": count})


@app.timer_trigger(schedule="%KEYWORD_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def dsl_keyword_watch_report(timer) -> None:
    _log_placeholder("dsl_keyword_watch_report")
    count = run_report_job("keyword-watch")
    logging.info("Keyword watch report complete", extra={"incident_count": count})


@app.timer_trigger(schedule="%LEADERSHIP_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def leadership_summary_report(timer) -> None:
    _log_placeholder("leadership_summary_report")
    count = run_report_job("leadership-summary")
    logging.info("Leadership summary report complete", extra={"incident_count": count})


@app.timer_trigger(schedule="%TEACHER_SUMMARY_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def teacher_summary_report(timer) -> None:
    _log_placeholder("teacher_summary_report")
    count = run_report_job("teacher-summary")
    logging.info("Teacher summary report complete", extra={"incident_count": count})


@app.timer_trigger(schedule="%RETENTION_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def reporting_retention(timer) -> None:
    _log_placeholder("reporting_retention")
    count = run_report_job("retention")
    logging.info("Reporting retention complete", extra={"deleted_count": count})
