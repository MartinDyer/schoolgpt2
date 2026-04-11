from __future__ import annotations

import logging

import azure.functions as func

from reporting.runtime import get_settings
from reporting.services import (
    run_dsl_daily_report,
    run_keyword_watch_report,
    run_leadership_summary_report,
    run_reporting_retention,
    run_teacher_summary_report,
    run_usage_daily_report,
)

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
def dsl_daily_report(timer: func.TimerRequest) -> None:
    _log_placeholder("dsl_daily_report")
    count = run_dsl_daily_report()
    logging.info("DSL daily report complete", extra={"incident_count": count})


@app.timer_trigger(schedule="%USAGE_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def usage_daily_report(timer: func.TimerRequest) -> None:
    _log_placeholder("usage_daily_report")
    count = run_usage_daily_report()
    logging.info("Usage daily report complete", extra={"summary_count": count})


@app.timer_trigger(schedule="%KEYWORD_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def dsl_keyword_watch_report(timer: func.TimerRequest) -> None:
    _log_placeholder("dsl_keyword_watch_report")
    count = run_keyword_watch_report()
    logging.info("Keyword watch report complete", extra={"incident_count": count})


@app.timer_trigger(schedule="%LEADERSHIP_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def leadership_summary_report(timer: func.TimerRequest) -> None:
    _log_placeholder("leadership_summary_report")
    count = run_leadership_summary_report()
    logging.info("Leadership summary report complete", extra={"incident_count": count})


@app.timer_trigger(schedule="%TEACHER_SUMMARY_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def teacher_summary_report(timer: func.TimerRequest) -> None:
    _log_placeholder("teacher_summary_report")
    count = run_teacher_summary_report()
    logging.info("Teacher summary report complete", extra={"incident_count": count})


@app.timer_trigger(schedule="%RETENTION_REPORT_SCHEDULE%", arg_name="timer", run_on_startup=False, use_monitor=True)
def reporting_retention(timer: func.TimerRequest) -> None:
    _log_placeholder("reporting_retention")
    count = run_reporting_retention()
    logging.info("Reporting retention complete", extra={"deleted_count": count})
