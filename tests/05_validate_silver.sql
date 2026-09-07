-- Databricks notebook source
-- Name: 05 - Silver Validation
-- Purpose: Stop the pipeline when clean keys, domains, or conformed relationships fail.
-- Grain: One validation summary row per Silver table.

WITH validation AS (
  SELECT
    'courses_clean' AS table_name,
    COUNT(*) AS row_count,
    COUNT_IF(code_module IS NULL OR code_presentation IS NULL) AS null_keys,
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation)) AS duplicate_keys,
    COUNT_IF(module_presentation_length <= 0) AS invalid_values,
    CAST(0 AS BIGINT) AS orphan_rows
  FROM IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean')

  UNION ALL

  SELECT
    'assessments_clean',
    COUNT(*),
    COUNT_IF(assessment.id_assessment IS NULL),
    COUNT(*) - COUNT(DISTINCT assessment.id_assessment),
    COUNT_IF(
      assessment.assessment_type NOT IN ('CMA', 'TMA', 'Exam')
      OR assessment.weight NOT BETWEEN 0 AND 100
    ),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_silver.assessments_clean') AS assessment
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean') AS course
    ON assessment.code_module = course.code_module
    AND assessment.code_presentation = course.code_presentation

  UNION ALL

  SELECT
    'vle_clean',
    COUNT(*),
    COUNT_IF(activity.id_site IS NULL),
    COUNT(*) - COUNT(DISTINCT STRUCT(activity.code_module, activity.code_presentation, activity.id_site)),
    COUNT_IF(
      activity.activity_type IS NULL
      OR (activity.week_from IS NOT NULL AND activity.week_to IS NOT NULL AND activity.week_from > activity.week_to)
    ),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_silver.vle_clean') AS activity
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean') AS course
    ON activity.code_module = course.code_module
    AND activity.code_presentation = course.code_presentation

  UNION ALL

  SELECT
    'student_info_clean',
    COUNT(*),
    COUNT_IF(student.id_student IS NULL),
    COUNT(*) - COUNT(DISTINCT STRUCT(student.code_module, student.code_presentation, student.id_student)),
    COUNT_IF(
      student.final_result NOT IN ('Withdrawn', 'Fail', 'Pass', 'Distinction')
      OR student.studied_credits <= 0
    ),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean') AS student
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean') AS course
    ON student.code_module = course.code_module
    AND student.code_presentation = course.code_presentation

  UNION ALL

  SELECT
    'student_registration_clean',
    COUNT(*),
    COUNT_IF(registration.id_student IS NULL),
    COUNT(*) - COUNT(
      DISTINCT STRUCT(registration.code_module, registration.code_presentation, registration.id_student)
    ),
    COUNT_IF(
      registration.date_registration IS NOT NULL
      AND registration.date_unregistration IS NOT NULL
      AND registration.date_unregistration < registration.date_registration
    ),
    COUNT_IF(student.id_student IS NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_registration_clean') AS registration
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean') AS student
    ON registration.code_module = student.code_module
    AND registration.code_presentation = student.code_presentation
    AND registration.id_student = student.id_student

  UNION ALL

  SELECT
    'student_assessment_clean',
    COUNT(*),
    COUNT_IF(submission.id_assessment IS NULL OR submission.id_student IS NULL),
    COUNT(*) - COUNT(DISTINCT STRUCT(submission.id_assessment, submission.id_student)),
    COUNT_IF(submission.score < 0 OR submission.score > 100),
    COUNT_IF(assessment.id_assessment IS NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_assessment_clean') AS submission
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.assessments_clean') AS assessment
    ON submission.id_assessment = assessment.id_assessment

  UNION ALL

  SELECT
    'student_vle_clean',
    COUNT(*),
    COUNT_IF(
      interaction.id_student IS NULL
      OR interaction.id_site IS NULL
      OR interaction.activity_date IS NULL
    ),
    COUNT(*) - COUNT(
      DISTINCT STRUCT(
        interaction.code_module,
        interaction.code_presentation,
        interaction.id_student,
        interaction.id_site,
        interaction.activity_date
      )
    ),
    COUNT_IF(interaction.sum_click <= 0),
    COUNT_IF(activity.id_site IS NULL)
  FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_vle_clean') AS interaction
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.vle_clean') AS activity
    ON interaction.code_module = activity.code_module
    AND interaction.code_presentation = activity.code_presentation
    AND interaction.id_site = activity.id_site
),
results AS (
  SELECT
    table_name,
    row_count,
    null_keys,
    duplicate_keys,
    invalid_values,
    orphan_rows,
    CASE
      WHEN row_count > 0
        AND null_keys = 0
        AND duplicate_keys = 0
        AND invalid_values = 0
        AND orphan_rows = 0
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
  orphan_rows,
  status,
  ASSERT_TRUE(
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) OVER () = 0,
    'one or more Silver tables failed validation; review the table-level metrics'
  ) AS silver_validation_check
FROM results
ORDER BY table_name;
