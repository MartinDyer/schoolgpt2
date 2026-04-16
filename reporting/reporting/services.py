from __future__ import annotations

import logging
import json
from urllib import request

from reporting.runtime import get_settings


def run_dsl_daily_report() -> int:
    return _run_backend_report("dsl-daily")


def run_usage_daily_report() -> int:
    return _run_backend_report("usage-daily")


def run_keyword_watch_report() -> int:
    return _run_backend_report("keyword-watch")


def run_leadership_summary_report() -> int:
    return _run_backend_report("leadership-summary")


def run_teacher_summary_report() -> int:
    return _run_backend_report("teacher-summary")


def run_reporting_retention() -> int:
    return _run_backend_report("retention")


def _run_backend_report(path: str) -> int:
    settings = get_settings()
    url = f"{settings.normalized_reporting_api_base}/run/{path}"
    req = request.Request(
        url,
        data=b"{}",
        headers={
            "Content-Type": "application/json",
            "x-reporting-key": settings.reporting_api_key,
        },
        method="POST",
    )
    with request.urlopen(req, timeout=120) as resp:
        payload = json.loads(resp.read().decode("utf-8"))
        if not payload.get("ok"):
            raise RuntimeError(f"Backend reporting endpoint failed for {path}: {payload}")
        return int(payload.get("count", 0))
