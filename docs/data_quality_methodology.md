# Data quality methodology

## Quality hierarchy

Every pipeline run appends one row per check to `oulad_dq.dq_check_results`. The dashboard then aggregates checks in this order:

```text
check result -> dataset score -> quality dimension score -> overall run score
```

Scores are weighted by evaluated values:

```text
score = 100 * sum(passed_count) / sum(total_count)
```

This avoids a naive average in which a ten-row check has the same influence as a ten-million-row check. The score is a monitoring KPI, not a scientific measure of truth.

## Check contract

Each check records what was tested, the expectation, threshold, severity, owner, evaluated count, failed count, score, status, execution timestamp, and run identifier. The covered dimensions are completeness, uniqueness, validity, consistency, referential integrity, and timeliness or volume.

Accuracy against real-world truth cannot be proven from OULAD alone because no independent ground-truth source is supplied. The pipeline therefore does not label internal consistency checks as accuracy checks. Add an `ACCURACY` rule only when a trusted external reference is available.

Status is assigned as follows:

- `PASS`: no evaluated value failed.
- `WARNING`: some values failed but the failure percentage remains within the threshold.
- `FAIL`: the failure percentage exceeds the threshold or the dataset is empty.

Only a `CRITICAL` failure stops the pipeline. Medium-severity volume drift and known nullable fields remain visible without blocking valid data. The official 173 null assessment scores, for example, are monitored with a one-percent threshold instead of being silently imputed.

## Layer gates

| Layer | Main checks | Gate behavior |
| --- | --- | --- |
| Bronze | Schema parsing, required identifiers, source keys, accepted values, source volume | Stop on critical schema or source-contract failure |
| Silver | Unique grains, allowed ranges, parent relationships, score null rate | Stop on broken clean keys or relationships |
| Gold | Dimension keys, fact grains, direct conformed keys, fact reconciliation | Stop on mart grain or referential failure |
| Analytics | Output grains, metric bounds, row reconciliation | Stop before dashboard views refresh |

## Dashboard views

`dq_latest_check_results` provides check-level drill-down. The remaining views provide weighted overview, dimension, dataset, problem, history, and source-volume datasets. The views read the persisted history and never overwrite previous runs.

The dashboard should show overall health, status counts, critical failures, affected datasets, last checked time, problem owners, and drill-down from run to dataset to check.
