-- Databricks notebook source
-- Name: 06 - Gold Dimensions
-- Purpose: Build conformed course, student, assessment, and VLE activity dimensions.
-- Grain: One row per business entity represented by each dimension.

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_gold.dim_course_presentation')
USING DELTA
AS
SELECT
  SHA2(CONCAT_WS('||', code_module, code_presentation), 256) AS course_presentation_key,
  code_module,
  code_presentation,
  module_presentation_length
FROM IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean');

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_gold.dim_student')
USING DELTA
AS
SELECT
  SHA2(CAST(id_student AS STRING), 256) AS student_key,
  id_student,
  gender,
  region,
  highest_education,
  imd_band,
  age_band,
  disability
FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean')
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY id_student
  ORDER BY code_presentation DESC, code_module DESC
) = 1;

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_gold.dim_assessment')
USING DELTA
AS
SELECT
  SHA2(CAST(assessment.id_assessment AS STRING), 256) AS assessment_key,
  course.course_presentation_key,
  assessment.id_assessment,
  assessment.code_module,
  assessment.code_presentation,
  assessment.assessment_type,
  assessment.assessment_date,
  assessment.weight
FROM IDENTIFIER(oulad_catalog || '.oulad_silver.assessments_clean') AS assessment
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_course_presentation') AS course
  ON assessment.code_module = course.code_module
  AND assessment.code_presentation = course.code_presentation;

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_gold.dim_vle_activity')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS('||', activity.code_module, activity.code_presentation, CAST(activity.id_site AS STRING)),
    256
  ) AS vle_activity_key,
  course.course_presentation_key,
  activity.id_site,
  activity.code_module,
  activity.code_presentation,
  activity.activity_type,
  activity.week_from,
  activity.week_to
FROM IDENTIFIER(oulad_catalog || '.oulad_silver.vle_clean') AS activity
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_course_presentation') AS course
  ON activity.code_module = course.code_module
  AND activity.code_presentation = course.code_presentation;
