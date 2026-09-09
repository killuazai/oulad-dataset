# Metabase dashboard build guide

The assignment dashboard should use the validated tables in
`ftw-week-07.04-analytics`. The Databricks Lakeview exports under `dashboards/`
remain optional portfolio artifacts; they do not replace the required Metabase
dashboard.

## Connect the data

1. Add the Databricks SQL warehouse as a Metabase database.
2. Synchronize schemas `03-mart` and `04-analytics`.
3. Create a collection named **OULAD Student Performance & Engagement**.
4. Save each statement from `dashboard_queries.sql`. Use queries 1 and 2 as
   source models for the KPI number cards; create one number question per metric.

## Dashboard layout

| Row | Card | Visualization |
|---:|---|---|
| 1 | Total Enrollments, Successful Outcome Rate, Withdrawal Rate, Average Score | Number cards |
| 2 | Enrollment Outcomes by Module Presentation | Stacked bar |
| 2 | Top Withdrawal-Rate Presentations | Horizontal bar |
| 3 | Engagement by Final Result | Grouped bar |
| 3 | Weekly VLE Activity | Line chart |
| 4 | Assessment Performance by Type | Grouped/combo chart |
| 4 | Late Submission Rate | Horizontal bar |
| 5 | Withdrawal Rate by Age Band | Horizontal bar |
| 5 | Rule-Based Risk Distribution | Stacked bar |

## Filters

Add `code_module` and `code_presentation` as dashboard-wide filters. Add
`assessment_type`, `final_result`, and `risk_level` only to cards containing
those fields. In every saved SQL question, configure these variables as
**Field Filters** and map each one to the same-named column in that question's
base table. Empty selections mean **All**.

Rates must be calculated from additive totals. Do not average stored rates.
Risk is a transparent screening rule, not a trained prediction. Negative
relative weeks are valid pre-presentation activity and must remain visible.
