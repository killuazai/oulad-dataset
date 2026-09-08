-- Databricks notebook source
-- Name: 06 - Gold Dimensions
-- Purpose: Build conformed dimensions that every BI fact joins to directly.
-- Grain: One row per business entity represented by each dimension.

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_module_presentation')
USING DELTA
AS
SELECT
  SHA2(CONCAT_WS('||', code_module, code_presentation), 256) AS module_presentation_key,
  code_module,
  code_presentation,
  CAST(SUBSTRING(code_presentation, 1, 4) AS INT) AS presentation_year,
  SUBSTRING(code_presentation, 5, 1) AS presentation_term,
  CASE SUBSTRING(code_presentation, 5, 1)
    WHEN 'B' THEN 'February start'
    WHEN 'J' THEN 'October start'
    ELSE 'Other start'
  END AS presentation_term_name,
  module_presentation_length
FROM IDENTIFIER(clean_namespace || '.courses_clean');

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_student')
USING DELTA
AS
SELECT DISTINCT
  SHA2(CAST(id_student AS STRING), 256) AS student_key,
  id_student
FROM IDENTIFIER(clean_namespace || '.student_info_clean');

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_demographics')
USING DELTA
AS
SELECT DISTINCT
  SHA2(
    CONCAT_WS(
      '||',
      COALESCE(gender, 'UNKNOWN'),
      COALESCE(region, 'UNKNOWN'),
      COALESCE(highest_education, 'UNKNOWN'),
      COALESCE(imd_band, 'UNKNOWN'),
      COALESCE(age_band, 'UNKNOWN'),
      COALESCE(disability, 'UNKNOWN')
    ),
    256
  ) AS demographics_key,
  gender,
  region,
  highest_education,
  imd_band,
  age_band,
  disability
FROM IDENTIFIER(clean_namespace || '.student_info_clean');

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_assessment')
USING DELTA
AS
SELECT
  SHA2(CAST(id_assessment AS STRING), 256) AS assessment_key,
  id_assessment,
  code_module,
  code_presentation,
  assessment_type,
  assessment_date,
  weight
FROM IDENTIFIER(clean_namespace || '.assessments_clean');

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_vle_activity')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS('||', code_module, code_presentation, CAST(id_site AS STRING)),
    256
  ) AS vle_activity_key,
  id_site,
  code_module,
  code_presentation,
  activity_type,
  week_from,
  week_to
FROM IDENTIFIER(clean_namespace || '.vle_clean');

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_relative_date')
USING DELTA
AS
WITH date_bounds AS (
  SELECT MIN(relative_day) AS minimum_day, MAX(relative_day) AS maximum_day
  FROM (
    SELECT assessment_date AS relative_day
    FROM IDENTIFIER(clean_namespace || '.assessments_clean')

    UNION ALL

    SELECT date_submitted
    FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')

    UNION ALL

    SELECT activity_date
    FROM IDENTIFIER(clean_namespace || '.student_vle_clean')

    UNION ALL

    SELECT date_registration
    FROM IDENTIFIER(clean_namespace || '.student_registration_clean')

    UNION ALL

    SELECT date_unregistration
    FROM IDENTIFIER(clean_namespace || '.student_registration_clean')
  ) AS source_dates
  WHERE relative_day IS NOT NULL
),
relative_days AS (
  SELECT EXPLODE(SEQUENCE(minimum_day, maximum_day)) AS relative_day
  FROM date_bounds
)
SELECT
  SHA2(CAST(relative_day AS STRING), 256) AS relative_date_key,
  relative_day,
  FLOOR(relative_day / 7) AS relative_week,
  CASE
    WHEN relative_day < 0 THEN 'BEFORE PRESENTATION'
    WHEN relative_day <= 28 THEN 'WEEKS 0-4'
    WHEN relative_day <= 84 THEN 'WEEKS 5-12'
    WHEN relative_day <= 168 THEN 'WEEKS 13-24'
    ELSE 'WEEK 25+'
  END AS course_phase
FROM relative_days;
