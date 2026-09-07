-- Databricks notebook source
-- Name: 14 - Data Quality Dashboard Views
-- Purpose: Publish dashboard-ready latest-run, drill-down, and historical quality metrics.
-- Grain: Documented separately for each view.

CREATE OR REPLACE VIEW IDENTIFIER(oulad_catalog || '.oulad_dq.dq_latest_check_results')
AS
WITH ranked_runs AS (
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY executed_at DESC, run_id DESC) AS run_rank
  FROM IDENTIFIER(oulad_catalog || '.oulad_dq.dq_check_results')
)
SELECT
  run_id,
  executed_at,
  layer,
  dataset_name,
  column_name,
  check_name,
  quality_dimension,
  check_type,
  expectation,
  threshold_pct,
  severity,
  check_owner,
  total_count,
  failed_count,
  passed_count,
  score_pct,
  failure_pct,
  status
FROM ranked_runs
WHERE run_rank = 1;

CREATE OR REPLACE VIEW IDENTIFIER(oulad_catalog || '.oulad_dq.dq_dashboard_overview')
AS
SELECT
  run_id,
  MAX(executed_at) AS last_checked_at,
  CAST(100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0) AS DECIMAL(7, 2)) AS overall_score_pct,
  COUNT(*) AS checks_executed,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') AS critical_failures,
  SUM(failed_count) AS affected_values,
  COUNT(DISTINCT CASE WHEN status <> 'PASS' THEN dataset_name END) AS affected_datasets
FROM IDENTIFIER(oulad_catalog || '.oulad_dq.dq_latest_check_results')
GROUP BY run_id;

CREATE OR REPLACE VIEW IDENTIFIER(oulad_catalog || '.oulad_dq.dq_dashboard_dimension_scores')
AS
SELECT
  run_id,
  quality_dimension,
  CAST(100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0) AS DECIMAL(7, 2)) AS dimension_score_pct,
  COUNT(*) AS check_count,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  SUM(failed_count) AS affected_values,
  MAX(executed_at) AS last_checked_at
FROM IDENTIFIER(oulad_catalog || '.oulad_dq.dq_latest_check_results')
GROUP BY run_id, quality_dimension;

CREATE OR REPLACE VIEW IDENTIFIER(oulad_catalog || '.oulad_dq.dq_dashboard_dataset_scores')
AS
SELECT
  run_id,
  layer,
  dataset_name,
  CAST(100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0) AS DECIMAL(7, 2)) AS dataset_score_pct,
  COUNT(*) AS check_count,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  SUM(failed_count) AS affected_values,
  MAX(executed_at) AS last_checked_at
FROM IDENTIFIER(oulad_catalog || '.oulad_dq.dq_latest_check_results')
GROUP BY run_id, layer, dataset_name;

CREATE OR REPLACE VIEW IDENTIFIER(oulad_catalog || '.oulad_dq.dq_dashboard_problem_areas')
AS
SELECT
  run_id,
  layer,
  dataset_name,
  column_name,
  check_name,
  quality_dimension,
  check_type,
  expectation,
  threshold_pct,
  severity,
  check_owner,
  total_count,
  failed_count,
  failure_pct,
  score_pct,
  status,
  executed_at
FROM IDENTIFIER(oulad_catalog || '.oulad_dq.dq_latest_check_results')
WHERE status IN ('WARNING', 'FAIL')
ORDER BY
  CASE severity WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 ELSE 4 END,
  failed_count DESC;

CREATE OR REPLACE VIEW IDENTIFIER(oulad_catalog || '.oulad_dq.dq_dashboard_history')
AS
SELECT
  run_id,
  executed_at,
  CAST(100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0) AS DECIMAL(7, 2)) AS overall_score_pct,
  COUNT(*) AS checks_executed,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') AS critical_failures,
  SUM(failed_count) AS affected_values
FROM IDENTIFIER(oulad_catalog || '.oulad_dq.dq_check_results')
GROUP BY run_id, executed_at;

CREATE OR REPLACE VIEW IDENTIFIER(oulad_catalog || '.oulad_dq.dq_dashboard_volume_history')
AS
SELECT
  run_id,
  executed_at,
  dataset_name,
  total_count AS observed_row_count,
  failure_pct AS volume_difference_pct,
  status
FROM IDENTIFIER(oulad_catalog || '.oulad_dq.dq_check_results')
WHERE check_type = 'VOLUME';
