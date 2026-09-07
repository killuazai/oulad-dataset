# Data dictionary

## Shared source identifiers

| Column | Meaning |
| --- | --- |
| `code_module` | Anonymized module identifier |
| `code_presentation` | Anonymized presentation identifier, including year and start period |
| `id_student` | Anonymized learner identifier |
| `id_assessment` | Assessment identifier |
| `id_site` | VLE activity/site identifier |

## Bronze ingestion metadata

Every Bronze table adds:

| Column | Meaning |
| --- | --- |
| `_rescued_data` | Source fields that could not be parsed into the expected schema |
| `source_file` | Input file path captured from Databricks file metadata |
| `ingested_at` | Timestamp of the full-refresh load |

## Gold dimensions

### `dim_course_presentation`

| Column | Meaning |
| --- | --- |
| `course_presentation_key` | Hash of module and presentation |
| `module_presentation_length` | Presentation duration in days |

### `dim_student`

| Column | Meaning |
| --- | --- |
| `student_key` | Hash of `id_student` |
| `gender` | Source gender category |
| `region` | Learner region |
| `highest_education` | Highest education category reported in OULAD |
| `imd_band` | Index of Multiple Deprivation band; nullable in the source |
| `age_band` | Source age category |
| `disability` | `Y` or `N` disability indicator |

### `dim_assessment`

| Column | Meaning |
| --- | --- |
| `assessment_key` | Hash of `id_assessment` |
| `assessment_type` | Computer-marked assessment, tutor-marked assessment, or exam |
| `assessment_date` | Scheduled day offset; exams may be null |
| `weight` | Assessment contribution percentage |

### `dim_vle_activity`

| Column | Meaning |
| --- | --- |
| `vle_activity_key` | Hash of course presentation and site identifier |
| `activity_type` | Normalized VLE activity category |
| `week_from`, `week_to` | Optional availability window in presentation weeks |

## Gold facts

### `fact_student_course`

| Column | Meaning |
| --- | --- |
| `student_course_key` | Hash of module, presentation, and learner |
| `num_of_prev_attempts` | Previous attempts at the module |
| `studied_credits` | Credits studied during the presentation |
| `date_registration` | Registration day offset; nullable |
| `date_unregistration` | Unregistration day offset; nullable |
| `final_result` | `Withdrawn`, `Fail`, `Pass`, or `Distinction` |

### `fact_assessment_submission`

| Column | Meaning |
| --- | --- |
| `assessment_submission_key` | Hash of assessment and learner |
| `date_submitted` | Submission day offset |
| `days_from_due_date` | Submission offset minus assessment due offset; positive means late |
| `is_banked` | Whether a previous result was transferred |
| `score` | Score from 0 through 100; nullable |
| `passed_assessment` | True when a non-null score is at least 40 |

### `fact_vle_interaction`

| Column | Meaning |
| --- | --- |
| `vle_interaction_key` | Hash of course, learner, site, and activity day |
| `activity_date` | Day offset of the interaction |
| `sum_click` | Clicks summed across source rows for the learner-site-day |

## Analytics tables

| Table | Grain | Purpose |
| --- | --- | --- |
| `learner_outcomes` | Course presentation | Enrollment and result counts and rates |
| `student_engagement` | Student-course | Active days, activities used, click totals, and activity span |
| `assessment_performance` | Course presentation and assessment type | Submission, score, pass, and lateness metrics |
| `at_risk_students` | Student-course | Transparent risk signals and screening level |
