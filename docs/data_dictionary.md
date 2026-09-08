# Data dictionary

## Shared natural identifiers

| Column | Meaning |
|---|---|
| `code_module` | Anonymized module identifier |
| `code_presentation` | Anonymized year and start-term identifier |
| `id_student` | Anonymized learner identifier |
| `id_assessment` | Assessment identifier |
| `id_site` | VLE activity identifier within a module presentation |

## Bronze metadata

| Column | Meaning |
|---|---|
| `_rescued_data` | Input values that did not match the explicit CSV schema |
| `source_file` | Source path from Databricks file metadata |
| `ingested_at` | Full-refresh ingestion timestamp |

## Gold dimensions

| Object | Key | Grain |
|---|---|---|
| `dim_student` | `student_key` | One anonymized learner identity |
| `dim_demographics` | `demographics_key` | One distinct demographic profile |
| `dim_module_presentation` | `module_presentation_key` | One module presentation |
| `dim_assessment` | `assessment_key` | One assessment |
| `dim_vle_activity` | `vle_activity_key` | One VLE site in one module presentation |
| `dim_relative_date` | `relative_date_key` | One relative course day |

`dim_registration_date`, `dim_unregistration_date`, `dim_submission_date`, `dim_due_date`, and `dim_activity_date` are role-playing views of `dim_relative_date`.

`dim_student` contains only `id_student`. `dim_demographics` contains gender, region, highest education, IMD band, age band, and disability. The facts store both keys directly.

## Gold facts

| Fact | Primary key | Grain | Main measures |
|---|---|---|---|
| `fact_student_enrollment` | `student_enrollment_key` | Learner and module presentation | Enrollment, outcome counters, credits, attempts |
| `fact_assessment_submission` | `assessment_submission_key` | Learner and assessment | Submission count, score, pass flag, due-day difference |
| `fact_vle_interaction` | `vle_interaction_key` | Learner, VLE site, relative day, module presentation | `sum_click`, `student_site_day_count` |

`student_site_day_count` is always one. It counts rows at the declared fact grain; it is not a click count. `sum_click` is the recorded engagement total.

## Assessment Analytics controls

| Column | Meaning | Additive? |
|---|---|---|
| `submission_count` | All submissions | Yes |
| `scored_submission_count` | Submissions with a non-null score | Yes |
| `missing_score_count` | Submissions with a null score | Yes |
| `score_sum` | Sum of non-null scores | Yes |
| `passed_submission_count` | Scored submissions with score at least 40 | Yes |
| `dated_submission_count` | Submissions whose assessment has a known due day | Yes |
| `late_submission_count` | Due-dated submissions after the due day | Yes |
| `submitting_students` | Distinct learners at module-presentation and assessment-type grain | No |
| `median_score` | Median at the declared table grain | No |

## Data-quality results

| Column | Meaning |
|---|---|
| `run_id`, `executed_at` | Validation-suite run identity and time |
| `layer` | Validation suite: BRONZE, SILVER, GOLD, or ANALYTICS; Accuracy checks use ANALYTICS |
| `dataset_name`, `column_name` | Evaluated object and field scope |
| `check_name`, `check_type`, `quality_dimension` | Rule definition and dimension |
| `expectation`, `threshold_pct`, `severity`, `check_owner` | Contract and accountability |
| `total_count`, `failed_count`, `passed_count` | Evaluated rule units |
| `score_pct`, `failure_pct`, `status` | Calculated rule outcome |

`failed_count` is a count of rule evaluations and is not guaranteed to be a distinct physical row count.
