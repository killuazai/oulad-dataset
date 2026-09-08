# OULAD repository alignment review and revision

Reviewed GitHub revision: `ff8990fa08624824793d1ee3b50e97303a2f1a15`.

## Final assessment

The Bronze, Silver, Gold, and Analytics data flow is structurally sound. The Gold model is a valid fact constellation with three facts sharing conformed dimensions and direct fact-to-dimension relationships. Student identity and demographic attributes are consolidated into one BI dimension without assuming that each learner has only one recorded profile. The 173 missing assessment scores are a legitimate source condition and must remain a non-blocking `WARNING`.

The repository was not fully reproducible because the dashboards read `genie_*` views that were not called by the full pipeline. The original latest-results view also selected one global validator run even though each validation suite creates its own run ID. Accuracy was listed but not measured, several documentation claims did not match the SQL, and some business-dashboard rates used incorrect aggregation denominators.

## Findings resolved by this pack

1. Consolidated Silver-to-Gold and Gold-to-Analytics control-total Accuracy checks into `tests/13_validate_analytics.sql`.
2. Updated the full runner so Analytics validation, including Accuracy, executes before dashboard views and `00_prepare_genie_sources.sql` is always refreshed.
3. Updated the core DQ views to select the latest run separately for every validation suite.
4. Added additive assessment counters so pass rate, average score, and late-submission rate can be aggregated correctly.
5. Added five role-playing date views while retaining one physical conformed `dim_relative_date` table.
6. Replaced the dashboard SQL reference queries with versions matching the current dashboard design.
7. Added exact dashboard revision prompts for changes that must be applied in the Databricks dashboard editor and re-exported.
8. Updated the final star-schema documentation and the repository README.
9. Merged `dim_demographics` into `dim_student`; updated facts, Gold validation, Genie sources, and documentation consistently.

## Upload instructions

Upload the contents of this folder into the repository root, preserving the relative paths. Files with the same path must replace the existing versions. Accuracy does not require a separate validator file or task.

After uploading:

1. Run `notebooks/00_run_full_pipeline.sql`.
2. Confirm four current validation suites: `BRONZE`, `SILVER`, `GOLD`, and `ANALYTICS`.
3. Confirm `ACCURACY` appears in `genie_dq_canonical_dimensions` with `MEASURED` status.
4. Paste `dashboards/DATA_QUALITY_DASHBOARD_REVISION_PROMPT.md` into the Databricks dashboard assistant.
5. Paste `dashboards/BUSINESS_DASHBOARD_REVISION_PROMPT.md` into the business dashboard assistant.
6. Re-export both `.lvdash.json` files and replace the older exports in `dashboards/`.

## Required Databricks job order

```text
Setup
  -> Bronze -> Bronze Validation -> Silver -> Silver Validation
  -> Gold Dimensions + Gold Facts -> Gold Validation
  -> Learner Outcomes + Assessment Performance + Student Engagement + At-Risk Students
  -> Analytics Validation (after all four Analytics outputs; includes Accuracy)
  -> Business Analytics Dashboard

Bronze Validation + Silver Validation + Gold Validation + Analytics Validation
  -> Data Quality Dashboard
```

All four Analytics tasks depend directly on Gold Validation and can run in parallel. `At-Risk Students` calculates its required engagement and assessment signals directly from validated Gold facts. Analytics Validation must wait for all four Analytics tables. The Business Analytics Dashboard depends directly only on Analytics Validation. The Data Quality Dashboard depends directly only on Bronze Validation, Silver Validation, Gold Validation, and Analytics Validation.

## Acceptance checks

```sql
SELECT layer, COUNT(*) AS checks
FROM `ftw-week-07`.`05-data-quality`.genie_latest_check_results
GROUP BY layer
ORDER BY layer;

SELECT dimension_key, measurement_status, weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.genie_dq_canonical_dimensions
ORDER BY dimension_order;

SELECT
  SUM(submission_count) AS submissions,
  SUM(scored_submission_count) AS scored_submissions,
  SUM(missing_score_count) AS missing_scores,
  SUM(dated_submission_count) AS dated_submissions,
  SUM(late_submission_count) AS late_submissions,
  100.0 * SUM(passed_submission_count) / NULLIF(SUM(scored_submission_count), 0)
    AS correct_pass_rate_pct,
  100.0 * SUM(late_submission_count) / NULLIF(SUM(dated_submission_count), 0)
    AS correct_late_submission_rate_pct
FROM `ftw-week-07`.`04-analytics`.assessment_performance;
```

For the supplied OULAD snapshot, expected assessment control values include 173,912 submissions, 173 missing scores, 173,739 scored submissions, and 171,047 submissions with a known due date.
