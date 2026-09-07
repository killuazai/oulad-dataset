-- Databricks notebook source
-- Name: 13 - Analytics Validation
-- Purpose: Persist reporting-level DQ results and stop on broken dashboard datasets.
-- Grain: One row per data quality check and pipeline run.

INSERT INTO IDENTIFIER(oulad_catalog || '.oulad_dq.dq_check_results')
WITH checks AS (
  SELECT
    'learner_outcomes' AS dataset_name, 'module_presentation_key' AS column_name,
    'learner outcome metrics are complete and bounded' AS check_name,
    'VALIDITY' AS quality_dimension, 'UNIQUE_RANGE' AS check_type,
    'One module presentation row with rates from 0 to 1' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct, 'CRITICAL' AS severity,
    'analytics' AS check_owner, COUNT(*) AS total_count,
    COUNT_IF(
      module_presentation_key IS NULL OR successful_outcome_rate NOT BETWEEN 0 AND 1
      OR withdrawal_rate NOT BETWEEN 0 AND 1 OR enrolled_students <= 0
    ) + COUNT(*) - COUNT(DISTINCT module_presentation_key) AS failed_count
  FROM IDENTIFIER(oulad_catalog || '.oulad_analytics.learner_outcomes')

  UNION ALL

  SELECT
    'student_engagement', 'student_enrollment_key', 'engagement rows reconcile with enrollments',
    'CONSISTENCY', 'UNIQUE_VOLUME_RECONCILIATION', 'One non-negative engagement row per enrollment',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      student_enrollment_key IS NULL OR active_days < 0 OR activities_used < 0 OR total_clicks < 0
    ) + COUNT(*) - COUNT(DISTINCT student_enrollment_key)
      + ABS(COUNT(*) - (
        SELECT COUNT(*) FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_student_enrollment')
      ))
  FROM IDENTIFIER(oulad_catalog || '.oulad_analytics.student_engagement')

  UNION ALL

  SELECT
    'assessment_performance', 'module_presentation_key, assessment_type',
    'assessment metrics are complete and bounded', 'VALIDITY', 'UNIQUE_RANGE',
    'One row per module presentation and assessment type with rates from 0 to 1',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      submission_count <= 0 OR average_score IS NULL OR average_score NOT BETWEEN 0 AND 100
      OR pass_rate IS NULL OR pass_rate NOT BETWEEN 0 AND 1
      OR late_submission_rate NOT BETWEEN 0 AND 1
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(module_presentation_key, assessment_type))
  FROM IDENTIFIER(oulad_catalog || '.oulad_analytics.assessment_performance')

  UNION ALL

  SELECT
    'at_risk_students', 'student_enrollment_key', 'risk rows reconcile with enrollments',
    'CONSISTENCY', 'UNIQUE_ACCEPTED_VALUES_VOLUME_RECONCILIATION',
    'One LOW, MEDIUM, or HIGH risk row per enrollment',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      student_enrollment_key IS NULL OR risk_score < 0 OR risk_score > 5
      OR risk_level NOT IN ('LOW', 'MEDIUM', 'HIGH')
    ) + COUNT(*) - COUNT(DISTINCT student_enrollment_key)
      + ABS(COUNT(*) - (
        SELECT COUNT(*) FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_student_enrollment')
      ))
  FROM IDENTIFIER(oulad_catalog || '.oulad_analytics.at_risk_students')
),
scored AS (
  SELECT
    *,
    CAST(CASE WHEN total_count = 0 THEN 100.0 ELSE 100.0 * failed_count / total_count END AS DECIMAL(7, 3))
      AS failure_pct,
    CAST(CASE WHEN total_count = 0 THEN 0.0
      ELSE 100.0 * GREATEST(total_count - failed_count, 0) / total_count END AS DECIMAL(7, 3)) AS score_pct
  FROM checks
),
classified AS (
  SELECT
    *,
    CASE WHEN total_count = 0 OR failure_pct > threshold_pct THEN 'FAIL'
      WHEN failed_count > 0 THEN 'WARNING' ELSE 'PASS' END AS status
  FROM scored
)
SELECT
  dq_run_id, dq_executed_at, 'ANALYTICS', dataset_name, column_name, check_name,
  quality_dimension, check_type, expectation, threshold_pct, severity, check_owner,
  total_count, failed_count, GREATEST(total_count - failed_count, 0), score_pct, failure_pct, status
FROM classified;

SELECT
  dataset_name,
  check_name,
  status,
  failed_count,
  ASSERT_TRUE(
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,
    'critical Analytics data quality check failed; inspect oulad_dq.dq_check_results'
  ) AS analytics_quality_gate
FROM IDENTIFIER(oulad_catalog || '.oulad_dq.dq_check_results')
WHERE run_id = dq_run_id AND layer = 'ANALYTICS'
ORDER BY dataset_name, check_name;
