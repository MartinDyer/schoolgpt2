# SchoolGPT Reporting Functions

Standalone Python Azure Functions project for reporting scheduling and backend proxying.

The backend owns reporting execution, including queries, watermarking, audit logging, rendering, and ACS email sending.
The Python Function App only schedules jobs and proxies `/api/reporting/run/*` calls.

Required Function App settings:
- `SCHOOL_NAME`
- `SCHOOL_TIMEZONE`
- `REPORTING_API_BASE`
- `REPORTING_API_KEY`
- `DSL_REPORT_SCHEDULE`
- `USAGE_REPORT_SCHEDULE`
- `KEYWORD_REPORT_SCHEDULE`
- `LEADERSHIP_REPORT_SCHEDULE`
- `TEACHER_SUMMARY_SCHEDULE`
- `RETENTION_REPORT_SCHEDULE`

Manual run examples:
- `python manual_run.py dsl-daily`
- `python manual_run.py usage-daily`
- `python manual_run.py keyword-watch`
- `python manual_run.py leadership-summary`
- `python manual_run.py teacher-summary`
- `python manual_run.py retention`
