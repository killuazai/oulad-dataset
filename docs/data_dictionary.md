# Data dictionary

## Shared identifiers

| Column | Meaning |
| --- | --- |
| `code_module` | Anonymized module identifier |
| `code_presentation` | Anonymized year and start-term identifier |
| `id_student` | Anonymized student identifier |
| `id_assessment` | Assessment identifier |
| `id_site` | VLE activity identifier |

## Bronze ingestion metadata

| Column | Meaning |
| --- | --- |
| `_rescued_data` | Values that did not match the explicit source schema |
| `source_file` | Input path captured from Databricks file metadata |
| `ingested_at` | Timestamp of the full-refresh load |

## Gold dimensions

| Table | Key | Important attributes |
| --- | --- | --- |
| `dim_student` | `student_key` | `id_student` |
| `dim_demographics` | `demographics_key` | `gender`, `region`, `highest_education`, `imd_band`, `age_band`, `disability` |
| `dim_module_presentation` | `module_presentation_key` | `code_module`, `code_presentation`, year, term, duration |
| `dim_assessment` | `assessment_key` | `id_assessment`, type, relative due day, weight |
| `dim_vle_activity` | `vle_activity_key` | `id_site`, activity type, optional availability weeks |
| `dim_relative_date` | `relative_date_key` | `relative_day`, `relative_week`, `course_phase` |

## Gold facts

### `fact_student_enrollment`

One row per student and module presentation. It contains direct keys to student, demographics, module presentation, registration date, and unregistration date. Additive measures include `enrollment_count`, `withdrawn_count`, `failed_count`, `passed_count`, and `distinction_count`; other context includes credits, prior attempts, relative registration dates, and final result.

### `fact_assessment_submission`

One row per student and assessment. It contains direct keys to student, demographics, module presentation, assessment, submitted date, and due date. Measures include `submission_count`, `score`, `days_from_due_date`, and `passed_assessment`. Null scores are valid source values and remain null.

### `fact_vle_interaction`

One row per student, VLE site, and relative day in one module presentation. It contains direct keys to student, demographics, module presentation, VLE activity, and activity date. Measures are `sum_click` and `interaction_count`.

## Data quality results

| Column | Meaning |
| --- | --- |
| `run_id`, `executed_at` | Pipeline execution identity and time |
| `layer`, `dataset_name`, `column_name` | Location of the evaluated data |
| `check_name`, `check_type`, `quality_dimension` | Check definition and quality category |
| `expectation`, `threshold_pct`, `severity`, `check_owner` | Operational rule and accountability |
| `total_count`, `failed_count`, `passed_count` | Evaluated and affected value counts |
| `score_pct`, `failure_pct`, `status` | Calculated quality result |

## Analytics outputs

| Table | Grain | Purpose |
| --- | --- | --- |
| `learner_outcomes` | Module presentation | Enrollment and outcome counts and rates |
| `student_engagement` | Student enrollment | Active days, activity count, clicks, and activity span |
| `assessment_performance` | Module presentation and assessment type | Score, pass, and lateness metrics |
| `at_risk_students` | Student enrollment | Transparent screening signals for review |
