-- Databricks notebook source
-- Name: 10 - Student Engagement
-- Purpose: Provide reusable VLE engagement measures for every student-course enrollment.
-- Grain: One row per student and course presentation.

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_analytics.student_engagement')
USING DELTA
AS
WITH engagement AS (
  SELECT
    course_presentation_key,
    student_key,
    COUNT(DISTINCT activity_date) AS active_days,
    COUNT(DISTINCT vle_activity_key) AS activities_used,
    SUM(sum_click) AS total_clicks,
    MIN(activity_date) AS first_activity_day,
    MAX(activity_date) AS last_activity_day
  FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_vle_interaction')
  GROUP BY
    course_presentation_key,
    student_key
)
SELECT
  enrollment.student_course_key,
  enrollment.course_presentation_key,
  enrollment.student_key,
  enrollment.code_module,
  enrollment.code_presentation,
  enrollment.id_student,
  COALESCE(engagement.active_days, 0) AS active_days,
  COALESCE(engagement.activities_used, 0) AS activities_used,
  COALESCE(engagement.total_clicks, 0) AS total_clicks,
  engagement.first_activity_day,
  engagement.last_activity_day,
  CASE
    WHEN COALESCE(engagement.active_days, 0) = 0 THEN 0.0
    ELSE engagement.total_clicks * 1.0 / engagement.active_days
  END AS average_clicks_per_active_day,
  enrollment.final_result
FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_student_course') AS enrollment
LEFT JOIN engagement
  ON enrollment.course_presentation_key = engagement.course_presentation_key
  AND enrollment.student_key = engagement.student_key;
