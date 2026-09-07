-- Databricks notebook source
-- Dataset: Overview KPI cards
SELECT
  last_checked_at,
  overall_score_pct,
  checks_executed,
  passed_checks,
  warning_checks,
  failed_checks,
  critical_failures,
  affected_datasets,
  affected_values
FROM workspace.oulad_dq.dq_dashboard_overview;

-- COMMAND ----------

-- Dataset: Quality dimension scores
SELECT
  quality_dimension,
  dimension_score_pct,
  passed_checks,
  warning_checks,
  failed_checks,
  affected_values
FROM workspace.oulad_dq.dq_dashboard_dimension_scores
ORDER BY dimension_score_pct;

-- COMMAND ----------

-- Dataset: Dataset health matrix
SELECT
  layer,
  dataset_name,
  dataset_score_pct,
  passed_checks,
  warning_checks,
  failed_checks,
  affected_values
FROM workspace.oulad_dq.dq_dashboard_dataset_scores
ORDER BY layer, dataset_score_pct;

-- COMMAND ----------

-- Dataset: Problem drill-down
SELECT
  severity,
  layer,
  dataset_name,
  column_name,
  check_name,
  expectation,
  check_owner,
  failed_count,
  failure_pct,
  status,
  executed_at
FROM workspace.oulad_dq.dq_dashboard_problem_areas;

-- COMMAND ----------

-- Dataset: Quality history
SELECT
  executed_at,
  overall_score_pct,
  passed_checks,
  warning_checks,
  failed_checks,
  critical_failures,
  affected_values
FROM workspace.oulad_dq.dq_dashboard_history
ORDER BY executed_at;

-- COMMAND ----------

-- Dataset: Source volume history
SELECT
  executed_at,
  dataset_name,
  observed_row_count,
  volume_difference_pct,
  status
FROM workspace.oulad_dq.dq_dashboard_volume_history
ORDER BY executed_at, dataset_name;
