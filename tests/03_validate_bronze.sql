-- Databricks notebook source
-- Name: 03 - Bronze Validation
-- Purpose: Stop the pipeline when source keys, domains, or parsing checks fail.
-- Grain: One validation summary row per Bronze table.

WITH validation AS (
  SELECT
    'courses' AS table_name,
    COUNT(*) AS row_count,
    COUNT_IF(code_module IS NULL OR code_presentation IS NULL) AS null_keys,
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation)) AS duplicate_keys,
    COUNT_IF(module_presentation_length IS NULL OR module_presentation_length <= 0) AS invalid_values,
    COUNT_IF(_rescued_data IS NOT NULL) AS rescued_rows
  FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.courses')

  UNION ALL

  SELECT
    'assessments',
    COUNT(*),
    COUNT_IF(id_assessment IS NULL OR code_module IS NULL OR code_presentation IS NULL),
    COUNT(*) - COUNT(DISTINCT id_assessment),
    COUNT_IF(
      assessment_type NOT IN ('CMA', 'TMA', 'Exam')
      OR weight IS NULL
      OR weight < 0
      OR weight > 100
      OR (assessment_type <> 'Exam' AND assessment_date IS NULL)
    ),
    COUNT_IF(_rescued_data IS NOT NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.assessments')

  UNION ALL

  SELECT
    'vle',
    COUNT(*),
    COUNT_IF(id_site IS NULL OR code_module IS NULL OR code_presentation IS NULL),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_site)),
    COUNT_IF(
      activity_type IS NULL
      OR TRIM(activity_type) = ''
      OR (week_from IS NOT NULL AND week_to IS NOT NULL AND week_from > week_to)
    ),
    COUNT_IF(_rescued_data IS NOT NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.vle')

  UNION ALL

  SELECT
    'student_info',
    COUNT(*),
    COUNT_IF(id_student IS NULL OR code_module IS NULL OR code_presentation IS NULL),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student)),
    COUNT_IF(
      gender NOT IN ('F', 'M')
      OR disability NOT IN ('N', 'Y')
      OR final_result NOT IN ('Withdrawn', 'Fail', 'Pass', 'Distinction')
      OR num_of_prev_attempts < 0
      OR studied_credits <= 0
    ),
    COUNT_IF(_rescued_data IS NOT NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.student_info')

  UNION ALL

  SELECT
    'student_registration',
    COUNT(*),
    COUNT_IF(id_student IS NULL OR code_module IS NULL OR code_presentation IS NULL),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student)),
    COUNT_IF(
      date_registration IS NOT NULL
      AND date_unregistration IS NOT NULL
      AND date_unregistration < date_registration
    ),
    COUNT_IF(_rescued_data IS NOT NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.student_registration')

  UNION ALL

  SELECT
    'student_assessment',
    COUNT(*),
    COUNT_IF(id_assessment IS NULL OR id_student IS NULL OR date_submitted IS NULL),
    COUNT(*) - COUNT(DISTINCT STRUCT(id_assessment, id_student)),
    COUNT_IF(is_banked NOT IN (0, 1) OR score < 0 OR score > 100),
    COUNT_IF(_rescued_data IS NOT NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.student_assessment')

  UNION ALL

  SELECT
    'student_vle',
    COUNT(*),
    COUNT_IF(
      id_student IS NULL
      OR id_site IS NULL
      OR code_module IS NULL
      OR code_presentation IS NULL
      OR activity_date IS NULL
    ),
    COUNT(*) - COUNT(
      DISTINCT STRUCT(code_module, code_presentation, id_student, id_site, activity_date)
    ),
    COUNT_IF(sum_click IS NULL OR sum_click <= 0),
    COUNT_IF(_rescued_data IS NOT NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.student_vle')
),
results AS (
  SELECT
    table_name,
    row_count,
    null_keys,
    duplicate_keys,
    invalid_values,
    rescued_rows,
    CASE
      WHEN row_count > 0
        AND null_keys = 0
        AND (duplicate_keys = 0 OR table_name = 'student_vle')
        AND invalid_values = 0
        AND rescued_rows = 0
      THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM validation
)
SELECT
  table_name,
  row_count,
  null_keys,
  duplicate_keys,
  invalid_values,
  rescued_rows,
  status,
  ASSERT_TRUE(
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) OVER () = 0,
    'one or more Bronze tables failed validation; review the table-level metrics'
  ) AS bronze_validation_check
FROM results
ORDER BY table_name;
