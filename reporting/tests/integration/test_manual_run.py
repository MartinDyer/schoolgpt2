from __future__ import annotations

import manual_run


def test_manual_run_dispatches_dsl_report(monkeypatch):
    monkeypatch.setattr(manual_run, 'run_dsl_daily_report', lambda: 3)
    monkeypatch.setattr(manual_run, 'run_usage_daily_report', lambda: 0)
    monkeypatch.setattr(manual_run, 'run_keyword_watch_report', lambda: 0)
    monkeypatch.setattr(manual_run.argparse.ArgumentParser, 'parse_args', lambda self: type('Args', (), {'report': 'dsl-daily'})())

    assert manual_run.main() == 3
