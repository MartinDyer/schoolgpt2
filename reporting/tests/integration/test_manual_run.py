from __future__ import annotations

import manual_run


def test_manual_run_dispatches_all_supported_jobs(monkeypatch):
    dispatched = []
    monkeypatch.setattr(manual_run, 'run_report_job', lambda report: dispatched.append(report) or 5)

    for report in sorted(manual_run.REPORT_ENDPOINTS):
        monkeypatch.setattr(manual_run.argparse.ArgumentParser, 'parse_args', lambda self, report=report: type('Args', (), {'report': report})())
        assert manual_run.main() == 5

    assert dispatched == sorted(manual_run.REPORT_ENDPOINTS)
