# OULAD enrollment-outcome revision

Upload the included files to the same paths in the GitHub repository, replacing
the existing versions.

After uploading, delete this obsolete dbt test from GitHub:

`tests/dbt/assert_demographics_outcome.sql`

That test refers to `final_result` and `is_withdrawn` in `dim_demographics`.
Those fields now correctly live in `04-analytics.student_cohort` at one student
enrollment per module presentation.

After the changes are merged, run the Databricks pipeline from `dbt_mart`:

1. `dbt deps`
2. `dbt build --full-refresh --select path:models/mart`
3. Gold validation
4. Analytics Learner Outcomes
5. Remaining Analytics tasks and Analytics validation

## Message for the classmate

Hi Cole! We reviewed the placement of `final_result`. Since its actual grain is
one student enrollment per module presentation (`id_student + code_module +
code_presentation`), it should not be part of `dim_demographics`.

We removed `final_result` and `is_withdrawn` from `dim_demographics`, including
`final_result` from the demographic SHA2 expression used by the dimension and
both fact tables. The demographic key now represents demographic attributes
only.

We retained `final_result` and derived `is_withdrawn` in
`04-analytics.student_cohort`, which has the correct enrollment grain. This
supports the withdrawal/dropout business question without adding a third Gold
fact, so the required Gold model remains exactly 5 dimensions and 2 facts.

After merging, please rerun `dbt build --full-refresh`, followed by the Analytics
tasks, so all demographic keys are rebuilt consistently.
