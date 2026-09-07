# Naming conventions

These rules keep SQL predictable across Databricks, GitHub, and BI tools.

## Database objects

| Object | Convention | Example |
| --- | --- | --- |
| Catalog | Existing workspace catalog | `workspace` |
| Layer schema | Project plus medallion layer | `oulad_bronze`, `oulad_silver`, `oulad_gold` |
| Quality schema | Project plus purpose | `oulad_dq` |
| Analytics schema | Project plus purpose | `oulad_analytics` |
| Dimension | `dim_` plus singular noun | `dim_student` |
| Fact | `fact_` plus singular business event | `fact_vle_interaction` |
| Dashboard view | `dq_dashboard_` plus subject | `dq_dashboard_overview` |
| Clean table | Source entity plus `_clean` | `student_info_clean` |

Bronze, Silver, and Gold correspond to the lecture terms Raw, Clean, and Mart. Use one vocabulary within a database path; do not mix names such as `raw_student_info` inside `oulad_bronze`.

## Columns and keys

- Use lowercase `snake_case` for every schema, table, view, column, and SQL alias.
- Use source business identifiers unchanged when their meaning is clear: `id_student`, `id_assessment`, and `id_site`.
- Name hashed dimensional keys `<entity>_key` and fact row keys `<event>_key`.
- Name measures with their unit or aggregation when ambiguity is possible: `score_pct`, `failed_count`, `relative_week`.
- Use `_at` for timestamps, `_date` for real calendar dates, and `_day` for OULAD relative-day offsets.
- Use `_count` for additive counts, `_rate` for values from 0 to 1, and `_pct` for values from 0 to 100.
- Name booleans as past-tense or state questions, such as `passed_assessment` and `is_banked`.

## SQL and repository files

- Prefix production SQL filenames with their execution number: `06_gold_dimensions.sql`.
- Use one stable grain per table and state it in the file header.
- Put reusable transformations in `src/`, validation gates in `tests/`, dashboard datasets in `dashboards/`, and safe experiments in `queries/`.
- Use descriptive branch names such as `feature/dq-dashboard` or `fix/vle-grain`.
- Use imperative commit subjects such as `Add persistent quality metrics`.

## Quality metadata

- Use uppercase controlled values for `layer`, `quality_dimension`, `check_type`, `severity`, and `status`.
- Allowed statuses are `PASS`, `WARNING`, and `FAIL`.
- Allowed severity values are `CRITICAL`, `HIGH`, `MEDIUM`, and `LOW`.
- Use team roles rather than a person's name for `check_owner`, such as `data_engineering` or `analytics`.
