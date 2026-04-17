from __future__ import annotations

import argparse

from reporting.services import REPORT_ENDPOINTS, run_report_job


def main() -> int:
    parser = argparse.ArgumentParser(description="Run SchoolGPT reporting jobs manually.")
    parser.add_argument(
        "report",
        choices=sorted(REPORT_ENDPOINTS),
        help="Report job to run",
    )
    args = parser.parse_args()
    return run_report_job(args.report)


if __name__ == "__main__":
    raise SystemExit(main())
