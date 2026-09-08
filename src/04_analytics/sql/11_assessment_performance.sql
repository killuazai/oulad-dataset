-- Databricks notebook source
-- Name: 11 - Assessment Performance
-- Purpose: Publish additive assessment controls and descriptive metrics.
-- Grain: One module presentation and assessment type.

DECLARE OR REPLACE VARIABLE analytics_namespace STRING
  DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING
  DEFAULT '`ftw-week-07`.`03-mart`';

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.assessment_performance')
USING DELTA
AS
SELECT
  submission.module_presentation_key,
  assessment.code_module,
  assessment.code_presentation,
  assessment.assessment_type,
  COUNT(*) AS submission_count,
  -- Non-additive outside this table's declared grain.
  COUNT(DISTINCT submission.student_key) AS submitting_students,
  COUNT_IF(submission.score IS NOT NULL) AS scored_submission_count,
  COUNT_IF(submission.score IS NULL) AS missing_score_count,
  SUM(COALESCE(submission.score, 0)) AS score_sum,
  COUNT_IF(submission.score IS NOT NULL AND submission.passed_assessment) AS passed_submission_count,
  COUNT_IF(assessment.assessment_date IS NOT NULL) AS dated_submission_count,
  COUNT_IF(
    assessment.assessment_date IS NOT NULL
    AND submission.days_from_due_date > 0
  ) AS late_submission_count,
  AVG(submission.score) AS average_score,
  -- Non-additive outside this table's declared grain.
  PERCENTILE_APPROX(submission.score, 0.5) AS median_score,
  1.0 * COUNT_IF(submission.score IS NOT NULL AND submission.passed_assessment)
    / NULLIF(COUNT_IF(submission.score IS NOT NULL), 0) AS pass_rate,
  1.0 * COUNT_IF(
    assessment.assessment_date IS NOT NULL
    AND submission.days_from_due_date > 0
  ) / NULLIF(COUNT_IF(assessment.assessment_date IS NOT NULL), 0) AS late_submission_rate
FROM IDENTIFIER(mart_namespace || '.fact_assessment_submission') AS submission
INNER JOIN IDENTIFIER(mart_namespace || '.dim_assessment') AS assessment
  ON submission.assessment_key = assessment.assessment_key
GROUP BY
  submission.module_presentation_key,
  assessment.code_module,
  assessment.code_presentation,
  assessment.assessment_type;
