from __future__ import annotations

import function_app


def test_scheduled_functions_dispatch_through_proxy(monkeypatch):
    dispatched: list[str] = []

    monkeypatch.setattr(function_app, "_log_placeholder", lambda _report_name: None)
    monkeypatch.setattr(function_app, "run_report_job", lambda report: dispatched.append(report) or 1)

    function_app.dsl_daily_report(None)
    function_app.usage_daily_report(None)
    function_app.dsl_keyword_watch_report(None)
    function_app.leadership_summary_report(None)
    function_app.teacher_summary_report(None)
    function_app.reporting_retention(None)

    assert dispatched == [
        "dsl-daily",
        "usage-daily",
        "keyword-watch",
        "leadership-summary",
        "teacher-summary",
        "retention",
    ]
