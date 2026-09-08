-- Databricks notebook source
-- Name: 06 - Gold Dimensions
-- Purpose: Build conformed dimensions that every BI fact joins to directly.
-- Grain: One row per business entity or learner-demographic profile.

DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

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
  SHA2(
    CONCAT_WS(
      '||',
      CAST(id_student AS STRING),
      COALESCE(gender, 'UNKNOWN'),
      COALESCE(region, 'UNKNOWN'),
      COALESCE(highest_education, 'UNKNOWN'),
      COALESCE(imd_band, 'UNKNOWN'),
      COALESCE(age_band, 'UNKNOWN'),
      COALESCE(disability, 'UNKNOWN')
    ),
    256
  ) AS student_key,
  id_student,
  gender,
  region,
  highest_education,
  imd_band,
  age_band,
  disability
FROM IDENTIFIER(clean_namespace || '.student_info_clean');

-- Demographics are folded into dim_student. Remove the obsolete standalone table.
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_demographics');

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

-- Role-playing views keep one physical date dimension while providing unambiguous BI relationships.
CREATE OR REPLACE VIEW IDENTIFIER(mart_namespace || '.dim_registration_date') AS
SELECT
  relative_date_key AS registration_date_key,
  relative_day AS registration_relative_day,
  relative_week AS registration_relative_week,
  course_phase AS registration_course_phase
FROM IDENTIFIER(mart_namespace || '.dim_relative_date');

CREATE OR REPLACE VIEW IDENTIFIER(mart_namespace || '.dim_unregistration_date') AS
SELECT
  relative_date_key AS unregistration_date_key,
  relative_day AS unregistration_relative_day,
  relative_week AS unregistration_relative_week,
  course_phase AS unregistration_course_phase
FROM IDENTIFIER(mart_namespace || '.dim_relative_date');

CREATE OR REPLACE VIEW IDENTIFIER(mart_namespace || '.dim_submission_date') AS
SELECT
  relative_date_key AS submitted_date_key,
  relative_day AS submitted_relative_day,
  relative_week AS submitted_relative_week,
  course_phase AS submitted_course_phase
FROM IDENTIFIER(mart_namespace || '.dim_relative_date');

CREATE OR REPLACE VIEW IDENTIFIER(mart_namespace || '.dim_due_date') AS
SELECT
  relative_date_key AS due_date_key,
  relative_day AS due_relative_day,
  relative_week AS due_relative_week,
  course_phase AS due_course_phase
FROM IDENTIFIER(mart_namespace || '.dim_relative_date');

CREATE OR REPLACE VIEW IDENTIFIER(mart_namespace || '.dim_activity_date') AS
SELECT
  relative_date_key AS activity_date_key,
  relative_day AS activity_relative_day,
  relative_week AS activity_relative_week,
  course_phase AS activity_course_phase
FROM IDENTIFIER(mart_namespace || '.dim_relative_date');
