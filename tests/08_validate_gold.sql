-- Databricks notebook source
-- Name: 08 - Gold Validation
-- Purpose: Persist mart-level grain and conformed-dimension checks and enforce critical gates.
-- Grain: One row per data quality check and pipeline run.

-- Explanation: Declare variables needed from the setup notebook.
DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';
DECLARE OR REPLACE VARIABLE dq_namespace STRING DEFAULT '`ftw-week-07`.`05-data-quality`';
DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

INSERT INTO IDENTIFIER(dq_namespace || '.dq_check_results')
WITH checks AS (
  SELECT
    'dim_module_presentation' AS dataset_name, 'module_presentation_key' AS column_name,
    'module presentation key is complete and unique' AS check_name,
    'UNIQUENESS' AS quality_dimension, 'NULL_UNIQUE' AS check_type,
    'One non-null key per module presentation' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct, 'CRITICAL' AS severity,
    'data_engineering' AS check_owner, COUNT(*) AS total_count,
    COUNT_IF(module_presentation_key IS NULL)
      + COUNT(*) - COUNT(DISTINCT module_presentation_key) AS failed_count
  FROM IDENTIFIER(mart_namespace || '.dim_module_presentation')

  UNION ALL

  SELECT
    'dim_student', 'student_key', 'student key is complete and unique',
    'UNIQUENESS', 'NULL_UNIQUE', 'One non-null key per student',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(student_key IS NULL) + COUNT(*) - COUNT(DISTINCT student_key)
  FROM IDENTIFIER(mart_namespace || '.dim_student')

  UNION ALL

  SELECT
    'dim_demographics', 'demographics_key', 'demographics key is complete and unique',
    'UNIQUENESS', 'NULL_UNIQUE', 'One non-null key per demographic profile',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(demographics_key IS NULL) + COUNT(*) - COUNT(DISTINCT demographics_key)
  FROM IDENTIFIER(mart_namespace || '.dim_demographics')

  UNION ALL

  SELECT
    'dim_assessment', 'assessment_key', 'assessment key is complete and unique',
    'UNIQUENESS', 'NULL_UNIQUE', 'One non-null key per assessment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(assessment_key IS NULL) + COUNT(*) - COUNT(DISTINCT assessment_key)
  FROM IDENTIFIER(mart_namespace || '.dim_assessment')

  UNION ALL

  SELECT
    'dim_vle_activity', 'vle_activity_key', 'VLE activity key is complete and unique',
    'UNIQUENESS', 'NULL_UNIQUE', 'One non-null key per VLE activity in a module presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(vle_activity_key IS NULL) + COUNT(*) - COUNT(DISTINCT vle_activity_key)
  FROM IDENTIFIER(mart_namespace || '.dim_vle_activity')

  UNION ALL

  SELECT
    'dim_relative_date', 'relative_date_key', 'relative date key is complete and unique',
    'UNIQUENESS', 'NULL_UNIQUE', 'One non-null key per relative course day',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(relative_date_key IS NULL) + COUNT(*) - COUNT(DISTINCT relative_date_key)
  FROM IDENTIFIER(mart_namespace || '.dim_relative_date')

  UNION ALL

  SELECT
    'fact_student_enrollment', 'student_enrollment_key',
    'enrollment grain and direct dimension keys are valid', 'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One enrollment row with valid student, module presentation, demographics, and optional relative dates',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      student.student_key IS NULL OR module.module_presentation_key IS NULL OR demo.demographics_key IS NULL
      OR (fact.registration_date_key IS NOT NULL AND registration_date.relative_date_key IS NULL)
      OR (fact.unregistration_date_key IS NOT NULL AND unregistration_date.relative_date_key IS NULL)
    ) + COUNT(*) - COUNT(DISTINCT fact.student_enrollment_key)
  FROM IDENTIFIER(mart_namespace || '.fact_student_enrollment') AS fact
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_student') AS student
    ON fact.student_key = student.student_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_module_presentation') AS module
    ON fact.module_presentation_key = module.module_presentation_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_demographics') AS demo
    ON fact.demographics_key = demo.demographics_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_relative_date') AS registration_date
    ON fact.registration_date_key = registration_date.relative_date_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_relative_date') AS unregistration_date
    ON fact.unregistration_date_key = unregistration_date.relative_date_key

  UNION ALL

  SELECT
    'fact_assessment_submission', 'assessment_submission_key',
    'assessment fact grain and direct dimension keys are valid', 'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One submission row with valid assessment, student, module, demographics, and relative dates',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      assessment.assessment_key IS NULL OR student.student_key IS NULL
      OR module.module_presentation_key IS NULL OR demo.demographics_key IS NULL
      OR submitted_date.relative_date_key IS NULL
      OR (fact.due_date_key IS NOT NULL AND due_date.relative_date_key IS NULL)
      OR fact.score < 0 OR fact.score > 100
    ) + COUNT(*) - COUNT(DISTINCT fact.assessment_submission_key)
  FROM IDENTIFIER(mart_namespace || '.fact_assessment_submission') AS fact
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_assessment') AS assessment
    ON fact.assessment_key = assessment.assessment_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_student') AS student
    ON fact.student_key = student.student_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_module_presentation') AS module
    ON fact.module_presentation_key = module.module_presentation_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_demographics') AS demo
    ON fact.demographics_key = demo.demographics_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_relative_date') AS submitted_date
    ON fact.submitted_date_key = submitted_date.relative_date_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_relative_date') AS due_date
    ON fact.due_date_key = due_date.relative_date_key

  UNION ALL

  SELECT
    'fact_vle_interaction', 'vle_interaction_key',
    'VLE fact grain and direct dimension keys are valid', 'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One student-site-day row with valid activity, student, module, demographics, and relative date',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      activity.vle_activity_key IS NULL OR student.student_key IS NULL
      OR module.module_presentation_key IS NULL OR demo.demographics_key IS NULL
      OR activity_date.relative_date_key IS NULL OR fact.sum_click <= 0
    ) + COUNT(*) - COUNT(DISTINCT fact.vle_interaction_key)
  FROM IDENTIFIER(mart_namespace || '.fact_vle_interaction') AS fact
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_vle_activity') AS activity
    ON fact.vle_activity_key = activity.vle_activity_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_student') AS student
    ON fact.student_key = student.student_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_module_presentation') AS module
    ON fact.module_presentation_key = module.module_presentation_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_demographics') AS demo
    ON fact.demographics_key = demo.demographics_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_relative_date') AS activity_date
    ON fact.activity_date_key = activity_date.relative_date_key

  UNION ALL

  SELECT
    'fact_student_enrollment', 'row_count', 'Gold enrollments reconcile with Silver',
    'CONSISTENCY', 'VOLUME_RECONCILIATION', 'Gold enrollment count equals clean student enrollment count',
    0, 'CRITICAL', 'data_engineering',
    (SELECT COUNT(*) FROM IDENTIFIER(clean_namespace || '.student_info_clean')),
    ABS(
      (SELECT COUNT(*) FROM IDENTIFIER(mart_namespace || '.fact_student_enrollment'))
      - (SELECT COUNT(*) FROM IDENTIFIER(clean_namespace || '.student_info_clean'))
    )
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
  dq_run_id, dq_executed_at, 'GOLD', dataset_name, column_name, check_name,
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
    'critical Gold data quality check failed; inspect 05-data-quality.dq_check_results'
  ) AS gold_quality_gate
FROM IDENTIFIER(dq_namespace || '.dq_check_results')
WHERE run_id = dq_run_id AND layer = 'GOLD'
ORDER BY dataset_name, check_name;