-- Databricks notebook source
-- Name: 11 - Assessment Performance
-- Purpose: Summarize submissions and scores by course presentation and assessment type.
-- Grain: One row per course presentation and assessment type.

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_analytics.assessment_performance')
USING DELTA
AS
SELECT
  assessment.course_presentation_key,
  assessment.code_module,
  assessment.code_presentation,
  assessment.assessment_type,
  COUNT(*) AS submission_count,
  COUNT(DISTINCT submission.student_key) AS submitting_students,
  COUNT_IF(submission.score IS NULL) AS missing_score_count,
  AVG(submission.score) AS average_score,
  PERCENTILE_APPROX(submission.score, 0.5) AS median_score,
  AVG(
    CASE
      WHEN submission.score IS NULL THEN NULL
      WHEN submission.passed_assessment THEN 1.0
      ELSE 0.0
    END
  ) AS pass_rate,
  AVG(
    CASE
      WHEN assessment.assessment_date IS NULL THEN NULL
      WHEN submission.days_from_due_date > 0 THEN 1.0
      ELSE 0.0
    END
  ) AS late_submission_rate
FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_assessment_submission') AS submission
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_assessment') AS assessment
  ON submission.assessment_key = assessment.assessment_key
GROUP BY
  assessment.course_presentation_key,
  assessment.code_module,
  assessment.code_presentation,
  assessment.assessment_type;
