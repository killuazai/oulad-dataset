# OULAD Genie and dashboard source pack

This pack supports two separate governed spaces:

1. OULAD Business Analytics — outcomes, engagement, assessment, demographics, and rule-based risk.
2. OULAD Data Quality — current suite health, six dimensions, datasets, issues, ownership, volume, and history.

`00_prepare_genie_sources.sql` is idempotent and is called by `notebooks/00_run_full_pipeline.sql`. It must run after Analytics validation (which includes Accuracy reconciliation) and core DQ view refresh. Both dashboards must wait for it.

The current DQ snapshot selects the latest completed run separately for BRONZE, SILVER, GOLD, and ANALYTICS because each suite has its own run ID. Accuracy checks are part of the ANALYTICS suite.

Accuracy means cross-layer transformation reconciliation. It is not an assertion of external real-world truth.

For assessment questions, aggregate additive controls:

```text
average score = SUM(score_sum) / SUM(scored_submission_count)
pass rate = SUM(passed_submission_count) / SUM(scored_submission_count)
late rate = SUM(late_submission_count) / SUM(dated_submission_count)
```

Do not average rates, distinct counts, or group medians.
