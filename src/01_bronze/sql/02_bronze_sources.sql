-- Databricks notebook source
-- Name: 02 - Bronze Sources
-- Purpose: Load the seven OULAD CSV files into typed, source-aligned Delta tables.
-- Grain: The original grain of each source file.

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_bronze.courses')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(module_presentation_length AS INT) AS module_presentation_length,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  oulad_source_path || '/courses.csv',
  format => 'csv',
  header => 'true',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'code_module STRING, code_presentation STRING, module_presentation_length INT'
);

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_bronze.assessments')
USING DELTA
AS
SELECT
  TRY_CAST(id_assessment AS BIGINT) AS id_assessment,
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRIM(assessment_type) AS assessment_type,
  TRY_CAST(date AS INT) AS assessment_date,
  TRY_CAST(weight AS DECIMAL(7, 3)) AS weight,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  oulad_source_path || '/assessments.csv',
  format => 'csv',
  header => 'true',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'id_assessment BIGINT, code_module STRING, code_presentation STRING, assessment_type STRING, date INT, weight DECIMAL(7, 3)'
);

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_bronze.vle')
USING DELTA
AS
SELECT
  TRY_CAST(id_site AS BIGINT) AS id_site,
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRIM(activity_type) AS activity_type,
  TRY_CAST(week_from AS INT) AS week_from,
  TRY_CAST(week_to AS INT) AS week_to,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  oulad_source_path || '/vle.csv',
  format => 'csv',
  header => 'true',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'id_site BIGINT, code_module STRING, code_presentation STRING, activity_type STRING, week_from INT, week_to INT'
);

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_bronze.student_info')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRIM(gender) AS gender,
  TRIM(region) AS region,
  TRIM(highest_education) AS highest_education,
  NULLIF(NULLIF(TRIM(imd_band), ''), '?') AS imd_band,
  TRIM(age_band) AS age_band,
  TRY_CAST(num_of_prev_attempts AS INT) AS num_of_prev_attempts,
  TRY_CAST(studied_credits AS INT) AS studied_credits,
  TRIM(disability) AS disability,
  TRIM(final_result) AS final_result,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  oulad_source_path || '/studentInfo.csv',
  format => 'csv',
  header => 'true',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'code_module STRING, code_presentation STRING, id_student BIGINT, gender STRING, region STRING, highest_education STRING, imd_band STRING, age_band STRING, num_of_prev_attempts INT, studied_credits INT, disability STRING, final_result STRING'
);

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_bronze.student_registration')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRY_CAST(date_registration AS INT) AS date_registration,
  TRY_CAST(date_unregistration AS INT) AS date_unregistration,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  oulad_source_path || '/studentRegistration.csv',
  format => 'csv',
  header => 'true',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'code_module STRING, code_presentation STRING, id_student BIGINT, date_registration INT, date_unregistration INT'
);

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_bronze.student_assessment')
USING DELTA
AS
SELECT
  TRY_CAST(id_assessment AS BIGINT) AS id_assessment,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRY_CAST(date_submitted AS INT) AS date_submitted,
  TRY_CAST(is_banked AS INT) AS is_banked,
  TRY_CAST(score AS DECIMAL(7, 3)) AS score,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  oulad_source_path || '/studentAssessment.csv',
  format => 'csv',
  header => 'true',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'id_assessment BIGINT, id_student BIGINT, date_submitted INT, is_banked INT, score DECIMAL(7, 3)'
);

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_bronze.student_vle')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRY_CAST(id_site AS BIGINT) AS id_site,
  TRY_CAST(date AS INT) AS activity_date,
  TRY_CAST(sum_click AS BIGINT) AS sum_click,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  oulad_source_path || '/studentVle.csv',
  format => 'csv',
  header => 'true',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'code_module STRING, code_presentation STRING, id_student BIGINT, id_site BIGINT, date INT, sum_click BIGINT'
);
