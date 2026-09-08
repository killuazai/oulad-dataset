-- Databricks notebook source
-- Databricks notebook source
-- Name: 13 - Analytics Validation
-- Purpose: Validate Analytics outputs, including cross-layer transformation Accuracy.
-- Grain: One row per data-quality check and validation-suite run.

DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';
DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE dq_namespace STRING DEFAULT '`ftw-week-07`.`05-data-quality`';
DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

INSERT INTO IDENTIFIER(dq_namespace || '.dq_check_results')
WITH silver_enrollment AS (
  SELECT
    COUNT(*) AS row_count,
    SUM(studied_credits) AS studied_credits,
    COUNT_IF(final_result = 'Withdrawn') AS withdrawn_count,
    COUNT_IF(final_result = 'Fail') AS failed_count,
    COUNT_IF(final_result = 'Pass') AS passed_count,
    COUNT_IF(final_result = 'Distinction') AS distinction_count
  FROM IDENTIFIER(clean_namespace || '.student_info_clean')
),
gold_enrollment AS (
  SELECT
    COUNT(*) AS row_count,
    SUM(studied_credits) AS studied_credits,
    SUM(withdrawn_count) AS withdrawn_count,
    SUM(failed_count) AS failed_count,
    SUM(passed_count) AS passed_count,
    SUM(distinction_count) AS distinction_count
  FROM IDENTIFIER(mart_namespace || '.fact_student_enrollment')
),
silver_assessment AS (
  SELECT
    COUNT(*) AS row_count,
    COUNT_IF(score IS NOT NULL) AS scored_count,
    COUNT_IF(score IS NULL) AS missing_score_count,
    SUM(COALESCE(score, 0)) AS score_sum
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')
),
gold_assessment AS (
  SELECT
    COUNT(*) AS row_count,
    COUNT_IF(score IS NOT NULL) AS scored_count,
    COUNT_IF(score IS NULL) AS missing_score_count,
    SUM(COALESCE(score, 0)) AS score_sum
  FROM IDENTIFIER(mart_namespace || '.fact_assessment_submission')
),
silver_vle AS (
  SELECT COUNT(*) AS row_count, SUM(sum_click) AS click_sum
  FROM IDENTIFIER(clean_namespace || '.student_vle_clean')
),
gold_vle AS (
  SELECT COUNT(*) AS row_count, SUM(sum_click) AS click_sum
  FROM IDENTIFIER(mart_namespace || '.fact_vle_interaction')
),
analytics_outcomes AS (
  SELECT
    SUM(enrolled_students) AS enrolled_count,
    SUM(withdrawn_students) AS withdrawn_count,
    SUM(failed_students) AS failed_count,
    SUM(passed_students) AS passed_count,
    SUM(distinction_students) AS distinction_count
  FROM IDENTIFIER(analytics_namespace || '.learner_outcomes')
),
analytics_engagement AS (
  SELECT COUNT(*) AS enrollment_count, SUM(total_clicks) AS click_sum
  FROM IDENTIFIER(analytics_namespace || '.student_engagement')
),
analytics_assessment AS (
  SELECT
    SUM(submission_count) AS submission_count,
    SUM(submission_count - missing_score_count) AS scored_count,
    SUM(missing_score_count) AS missing_score_count
  FROM IDENTIFIER(analytics_namespace || '.assessment_performance')
),
checks AS (
  SELECT
    'learner_outcomes' AS dataset_name,
    'module_presentation_key' AS column_name,
    'learner outcome metrics are complete and bounded' AS check_name,
    'VALIDITY' AS quality_dimension,
    'UNIQUE_RANGE_RECONCILIATION' AS check_type,
    'One row per module presentation; outcome totals equal enrollments; rates are 0 to 1' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct,
    'CRITICAL' AS severity,
    'analytics' AS check_owner,
    COUNT(*) AS total_count,
    COUNT_IF(
      module_presentation_key IS NULL
      OR successful_outcome_rate NOT BETWEEN 0 AND 1
      OR withdrawal_rate NOT BETWEEN 0 AND 1
      OR enrolled_students <= 0
      OR withdrawn_students + failed_students + passed_students + distinction_students
        <> enrolled_students
    ) + COUNT(*) - COUNT(DISTINCT module_presentation_key) AS failed_count
  FROM IDENTIFIER(analytics_namespace || '.learner_outcomes')

  UNION ALL

  SELECT
    'student_engagement', 'student_enrollment_key',
    'engagement rows reconcile with enrollments',
    'CONSISTENCY', 'UNIQUE_VOLUME_RECONCILIATION',
    'One non-negative engagement row per enrollment',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      student_enrollment_key IS NULL
      OR active_days < 0
      OR activities_used < 0
      OR total_clicks < 0
    )
      + COUNT(*) - COUNT(DISTINCT student_enrollment_key)
      + ABS(
        COUNT(*) - (
          SELECT COUNT(*)
          FROM IDENTIFIER(mart_namespace || '.fact_student_enrollment')
        )
      )
  FROM IDENTIFIER(analytics_namespace || '.student_engagement')

  UNION ALL

  SELECT
    'assessment_performance',
    'module_presentation_key, assessment_type',
    'assessment metrics and additive controls are valid',
    'VALIDITY', 'UNIQUE_RANGE_RECONCILIATION',
    'One row per group; counters reconcile; rates are 0 to 1',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      submission_count <= 0
      OR missing_score_count < 0
      OR missing_score_count > submission_count
      OR average_score IS NULL
      OR average_score NOT BETWEEN 0 AND 100
      OR pass_rate IS NULL
      OR pass_rate NOT BETWEEN 0 AND 1
      OR late_submission_rate NOT BETWEEN 0 AND 1
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(module_presentation_key, assessment_type))
      AS failed_count
  FROM IDENTIFIER(analytics_namespace || '.assessment_performance')

  UNION ALL

  SELECT
    'at_risk_students', 'student_enrollment_key',
    'risk rows reconcile with enrollments',
    'CONSISTENCY', 'UNIQUE_ACCEPTED_VALUES_VOLUME_RECONCILIATION',
    'One LOW, MEDIUM, or HIGH rule-based risk row per enrollment',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      student_enrollment_key IS NULL
      OR risk_score < 0
      OR risk_score > 5
      OR risk_level NOT IN ('LOW', 'MEDIUM', 'HIGH')
    )
      + COUNT(*) - COUNT(DISTINCT student_enrollment_key)
      + ABS(
        COUNT(*) - (
          SELECT COUNT(*)
          FROM IDENTIFIER(mart_namespace || '.fact_student_enrollment')
        )
      )
  FROM IDENTIFIER(analytics_namespace || '.at_risk_students')

  UNION ALL

  SELECT
    'student_enrollment_pipeline',
    'row_count, studied_credits, outcome counts',
    'Silver enrollment controls reconcile with Gold',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Six enrollment control totals are unchanged from Silver to Gold',
    0, 'CRITICAL', 'data_engineering', 6,
    CASE WHEN silver.row_count <> gold.row_count THEN 1 ELSE 0 END
      + CASE WHEN silver.studied_credits <> gold.studied_credits THEN 1 ELSE 0 END
      + CASE WHEN silver.withdrawn_count <> gold.withdrawn_count THEN 1 ELSE 0 END
      + CASE WHEN silver.failed_count <> gold.failed_count THEN 1 ELSE 0 END
      + CASE WHEN silver.passed_count <> gold.passed_count THEN 1 ELSE 0 END
      + CASE WHEN silver.distinction_count <> gold.distinction_count THEN 1 ELSE 0 END
  FROM silver_enrollment AS silver
  CROSS JOIN gold_enrollment AS gold

  UNION ALL

  SELECT
    'assessment_submission_pipeline',
    'row_count, scored_count, missing_score_count, score_sum',
    'Silver assessment controls reconcile with Gold',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Four assessment control totals are unchanged from Silver to Gold',
    0, 'CRITICAL', 'data_engineering', 4,
    CASE WHEN silver.row_count <> gold.row_count THEN 1 ELSE 0 END
      + CASE WHEN silver.scored_count <> gold.scored_count THEN 1 ELSE 0 END
      + CASE WHEN silver.missing_score_count <> gold.missing_score_count THEN 1 ELSE 0 END
      + CASE WHEN silver.score_sum <> gold.score_sum THEN 1 ELSE 0 END
  FROM silver_assessment AS silver
  CROSS JOIN gold_assessment AS gold

  UNION ALL

  SELECT
    'vle_interaction_pipeline', 'row_count, sum_click',
    'Silver VLE controls reconcile with Gold',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'VLE row count and click total are unchanged from Silver to Gold',
    0, 'CRITICAL', 'data_engineering', 2,
    CASE WHEN silver.row_count <> gold.row_count THEN 1 ELSE 0 END
      + CASE WHEN silver.click_sum <> gold.click_sum THEN 1 ELSE 0 END
  FROM silver_vle AS silver
  CROSS JOIN gold_vle AS gold

  UNION ALL

  SELECT
    'learner_outcomes', 'enrollment and outcome counts',
    'Gold enrollment controls reconcile with Analytics outcomes',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Five enrollment controls are unchanged in learner_outcomes',
    0, 'CRITICAL', 'analytics', 5,
    CASE WHEN gold.row_count <> analytics.enrolled_count THEN 1 ELSE 0 END
      + CASE WHEN gold.withdrawn_count <> analytics.withdrawn_count THEN 1 ELSE 0 END
      + CASE WHEN gold.failed_count <> analytics.failed_count THEN 1 ELSE 0 END
      + CASE WHEN gold.passed_count <> analytics.passed_count THEN 1 ELSE 0 END
      + CASE WHEN gold.distinction_count <> analytics.distinction_count THEN 1 ELSE 0 END
  FROM gold_enrollment AS gold
  CROSS JOIN analytics_outcomes AS analytics

  UNION ALL

  SELECT
    'student_engagement', 'enrollment_count, total_clicks',
    'Gold controls reconcile with Analytics engagement',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Enrollment count and click total are unchanged in student_engagement',
    0, 'CRITICAL', 'analytics', 2,
    CASE WHEN enrollment.row_count <> engagement.enrollment_count THEN 1 ELSE 0 END
      + CASE WHEN vle.click_sum <> engagement.click_sum THEN 1 ELSE 0 END
  FROM gold_enrollment AS enrollment
  CROSS JOIN gold_vle AS vle
  CROSS JOIN analytics_engagement AS engagement

  UNION ALL

  SELECT
    'assessment_performance',
    'submission_count, scored_count, missing_score_count',
    'Gold controls reconcile with Analytics assessment performance',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Three assessment controls are unchanged in assessment_performance',
    0, 'CRITICAL', 'analytics', 3,
    CASE WHEN gold.row_count <> analytics.submission_count THEN 1 ELSE 0 END
      + CASE WHEN gold.scored_count <> analytics.scored_count THEN 1 ELSE 0 END
      + CASE WHEN gold.missing_score_count <> analytics.missing_score_count THEN 1 ELSE 0 END
  FROM gold_assessment AS gold
  CROSS JOIN analytics_assessment AS analytics
),
scored AS (
  SELECT
    *,
    CAST(
      CASE WHEN total_count = 0 THEN 100.0 ELSE 100.0 * failed_count / total_count END
      AS DECIMAL(7, 3)
    ) AS failure_pct,
    CAST(
      CASE
        WHEN total_count = 0 THEN 0.0
        ELSE 100.0 * GREATEST(total_count - failed_count, 0) / total_count
      END AS DECIMAL(7, 3)
    ) AS score_pct
  FROM checks
),
classified AS (
  SELECT
    *,
    CASE
      WHEN total_count = 0 OR failure_pct > threshold_pct THEN 'FAIL'
      WHEN failed_count > 0 THEN 'WARNING'
      ELSE 'PASS'
    END AS status
  FROM scored
)
SELECT
  dq_run_id,
  dq_executed_at,
  'ANALYTICS',
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
  GREATEST(total_count - failed_count, 0),
  score_pct,
  failure_pct,
  status
FROM classified;

SELECT
  dataset_name,
  check_name,
  status,
  failed_count,
  ASSERT_TRUE(
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,
    'critical Analytics data-quality check failed; inspect dq_check_results'
  ) AS analytics_quality_gate
FROM IDENTIFIER(dq_namespace || '.dq_check_results')
WHERE run_id = dq_run_id
  AND layer = 'ANALYTICS'
ORDER BY dataset_name, check_name;
