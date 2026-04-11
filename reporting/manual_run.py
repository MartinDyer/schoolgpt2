from __future__ import annotations

import argparse

from reporting.services import run_dsl_daily_report, run_keyword_watch_report, run_usage_daily_report


def main() -> int:
    parser = argparse.ArgumentParser(description="Run SchoolGPT reporting jobs manually.")
    parser.add_argument(
        "report",
        choices=["dsl-daily", "usage-daily", "keyword-watch"],
        help="Report job to run",
    )
    args = parser.parse_args()

    if args.report == "dsl-daily":
        return run_dsl_daily_report()
    if args.report == "usage-daily":
        return run_usage_daily_report()
    return run_keyword_watch_report()


if __name__ == "__main__":
    raise SystemExit(main())
