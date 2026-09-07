-- Databricks notebook source
-- Name: 08 - Gold Validation
-- Purpose: Stop the pipeline when Gold keys, relationships, or row reconciliation fail.
-- Grain: One row per named quality check.

WITH checks AS (
  SELECT
    'dim_course_presentation is populated and unique' AS check_name,
    COUNT_IF(course_presentation_key IS NULL)
      + COUNT(*)
      - COUNT(DISTINCT course_presentation_key)
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END AS failed_rows
  FROM IDENTIFIER(oulad_catalog || '.oulad_gold.dim_course_presentation')

  UNION ALL

  SELECT
    'dim_student is populated and unique',
    COUNT_IF(student_key IS NULL)
      + COUNT(*)
      - COUNT(DISTINCT student_key)
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
  FROM IDENTIFIER(oulad_catalog || '.oulad_gold.dim_student')

  UNION ALL

  SELECT
    'dim_assessment keys and course references are valid',
    COUNT_IF(assessment.assessment_key IS NULL OR course.course_presentation_key IS NULL)
      + COUNT(*)
      - COUNT(DISTINCT assessment.assessment_key)
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
  FROM IDENTIFIER(oulad_catalog || '.oulad_gold.dim_assessment') AS assessment
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_course_presentation') AS course
    ON assessment.course_presentation_key = course.course_presentation_key

  UNION ALL

  SELECT
    'dim_vle_activity keys and course references are valid',
    COUNT_IF(activity.vle_activity_key IS NULL OR course.course_presentation_key IS NULL)
      + COUNT(*)
      - COUNT(DISTINCT activity.vle_activity_key)
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
  FROM IDENTIFIER(oulad_catalog || '.oulad_gold.dim_vle_activity') AS activity
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_course_presentation') AS course
    ON activity.course_presentation_key = course.course_presentation_key

  UNION ALL

  SELECT
    'fact_student_course grain and dimension references are valid',
    COUNT_IF(
      fact.student_course_key IS NULL
      OR course.course_presentation_key IS NULL
      OR student.student_key IS NULL
    )
      + COUNT(*)
      - COUNT(DISTINCT fact.student_course_key)
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
  FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_student_course') AS fact
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_course_presentation') AS course
    ON fact.course_presentation_key = course.course_presentation_key
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_student') AS student
    ON fact.student_key = student.student_key

  UNION ALL

  SELECT
    'fact_assessment_submission grain and dimension references are valid',
    COUNT_IF(
      fact.assessment_submission_key IS NULL
      OR assessment.assessment_key IS NULL
      OR student.student_key IS NULL
      OR fact.score < 0
      OR fact.score > 100
    )
      + COUNT(*)
      - COUNT(DISTINCT fact.assessment_submission_key)
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
  FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_assessment_submission') AS fact
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_assessment') AS assessment
    ON fact.assessment_key = assessment.assessment_key
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_student') AS student
    ON fact.student_key = student.student_key

  UNION ALL

  SELECT
    'fact_vle_interaction grain and dimension references are valid',
    COUNT_IF(
      fact.vle_interaction_key IS NULL
      OR activity.vle_activity_key IS NULL
      OR student.student_key IS NULL
      OR fact.sum_click <= 0
    )
      + COUNT(*)
      - COUNT(DISTINCT fact.vle_interaction_key)
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
  FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_vle_interaction') AS fact
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_vle_activity') AS activity
    ON fact.vle_activity_key = activity.vle_activity_key
  LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_student') AS student
    ON fact.student_key = student.student_key

  UNION ALL

  SELECT
    'student-course rows reconcile with Silver student info',
    ABS(
      (SELECT COUNT(*) FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_student_course'))
      - (SELECT COUNT(*) FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean'))
    )
)
SELECT
  check_name,
  failed_rows,
  CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
  ASSERT_TRUE(
    SUM(failed_rows) OVER () = 0,
    'one or more Gold checks failed; review the named checks'
  ) AS gold_validation_check
FROM checks
ORDER BY check_name;
