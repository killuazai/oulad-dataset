# Naming conventions

| Object | Convention | Example |
|---|---|---|
| Catalog | Course/week name, quoted because it contains hyphens | `ftw-week-07` |
| Ordered schema | Two-digit prefix and lowercase name | `01-raw`, `05-data-quality` |
| Physical dimension | `dim_` + singular entity | `dim_student` |
| Role-playing dimension view | `dim_` + role + `_date` | `dim_submission_date` |
| Fact | `fact_` + singular business process | `fact_assessment_submission` |
| Clean table | Source entity + `_clean` | `student_assessment_clean` |
| Analytics table | Descriptive lower snake case | `assessment_performance` |
| Core DQ view | `dq_dashboard_` + subject | `dq_dashboard_overview` |
| Governed dashboard/Genie view | `genie_` + subject | `genie_dq_problem_areas` |

Rules:

- Use lowercase `snake_case` for objects, columns, and aliases.
- Use uppercase controlled values for validation suite, quality dimension, severity, and status.
- Use `<entity>_key` for dimension keys and `<event>_key` for fact keys.
- Name objects from their declared grain: `dim_module_presentation`, `fact_student_enrollment`, `fact_assessment_submission`, and `fact_vle_interaction`.
- Preserve source identifiers such as `id_student`, `id_assessment`, and `id_site` as attributes. Do not use them as substitutes for the repository's conformed `_key` relationships.
- Use `_count` for additive counts, `_sum` for additive numeric totals, `_rate` for 0–1 values, and `_pct` for 0–100 values.
- Use `_at` for timestamps. OULAD offsets use `_day` or `relative_` names because they are not calendar dates.
- Use team roles such as `data_engineering` and `analytics` for `check_owner`.
- Allowed status values: `PASS`, `WARNING`, `FAIL`.
- Allowed severity values: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`.
- Validation suite values: `BRONZE`, `SILVER`, `GOLD`, `ANALYTICS`. Accuracy is a quality dimension within the Analytics suite, not a layer or suite.
- Production transformations belong in `src/`, gates in `tests/`, BI datasets in `dashboards/`, and experiments in `queries/`.
- Every table file states one explicit grain.

Hyphenated catalog and schema identifiers must be enclosed in backticks or passed through `IDENTIFIER()`.
