from __future__ import annotations

import json
from urllib import error, request

from reporting.runtime import get_settings


REPORT_ENDPOINTS = {
    "dsl-daily": "dsl-daily",
    "usage-daily": "usage-daily",
    "keyword-watch": "keyword-watch",
    "leadership-summary": "leadership-summary",
    "teacher-summary": "teacher-summary",
    "retention": "retention",
}


def run_dsl_daily_report() -> int:
    return run_report_job("dsl-daily")


def run_usage_daily_report() -> int:
    return run_report_job("usage-daily")


def run_keyword_watch_report() -> int:
    return run_report_job("keyword-watch")


def run_leadership_summary_report() -> int:
    return run_report_job("leadership-summary")


def run_teacher_summary_report() -> int:
    return run_report_job("teacher-summary")


def run_reporting_retention() -> int:
    return run_report_job("retention")


def run_report_job(job_name: str) -> int:
    path = REPORT_ENDPOINTS.get(job_name)
    if path is None:
        supported = ", ".join(sorted(REPORT_ENDPOINTS))
        raise ValueError(f"Unsupported report job '{job_name}'. Supported jobs: {supported}")
    return _run_backend_report(path)


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

    try:
        with request.urlopen(req, timeout=120) as resp:
            payload = _decode_backend_payload(resp.read(), path)
            return _extract_count(payload, path)
    except error.HTTPError as exc:
        payload = _decode_backend_payload(exc.read(), path)
        raise RuntimeError(_build_backend_error_message(path, payload, status_code=exc.code)) from exc
    except error.URLError as exc:
        raise RuntimeError(f"Backend reporting endpoint failed for {path}: transport error: {exc.reason}") from exc


def _decode_backend_payload(raw_body: bytes, path: str) -> dict:
    try:
        payload = json.loads(raw_body.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Backend reporting endpoint failed for {path}: invalid JSON response") from exc

    if not isinstance(payload, dict):
        raise RuntimeError(f"Backend reporting endpoint failed for {path}: invalid payload shape")
    return payload


def _extract_count(payload: dict, path: str) -> int:
    if payload.get("ok"):
        return int(payload.get("count", 0))
    raise RuntimeError(_build_backend_error_message(path, payload))


def _build_backend_error_message(path: str, payload: dict, status_code: int | None = None) -> str:
    raw_error = payload.get("error")
    error_payload = raw_error if isinstance(raw_error, dict) else {}
    code = error_payload.get("code", "unknown_error")
    message = error_payload.get("message") or payload.get("error") or "Unknown backend error"
    retryable = error_payload.get("retryable")
    request_id = error_payload.get("requestId", "")
    status_fragment = f" status={status_code}" if status_code is not None else ""
    retryable_fragment = f" retryable={retryable}" if retryable is not None else ""
    request_fragment = f" requestId={request_id}" if request_id else ""
    return f"Backend reporting endpoint failed for {path}:{status_fragment} code={code}{retryable_fragment}{request_fragment} message={message}"
