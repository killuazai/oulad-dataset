-- Databricks notebook source
-- Name: 01 - Setup
-- Purpose: Configure the run, create layer schemas, and verify the seven required OULAD files.
-- Grain: One validation row for the configured source directory.

DECLARE OR REPLACE VARIABLE oulad_catalog STRING DEFAULT 'workspace';
DECLARE OR REPLACE VARIABLE oulad_source_path STRING DEFAULT '/Volumes/workspace/default/oulad';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER(oulad_catalog || '.oulad_bronze');
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(oulad_catalog || '.oulad_silver');
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(oulad_catalog || '.oulad_gold');
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(oulad_catalog || '.oulad_analytics');

WITH expected_files AS (
  SELECT EXPLODE(
    ARRAY(
      'assessments.csv',
      'courses.csv',
      'studentAssessment.csv',
      'studentInfo.csv',
      'studentRegistration.csv',
      'studentVle.csv',
      'vle.csv'
    )
  ) AS file_name
),
actual_files AS (
  SELECT REGEXP_EXTRACT(path, '([^/]+)$', 1) AS file_name
  FROM READ_FILES(
    oulad_source_path || '/*.csv',
    format => 'binaryFile'
  )
),
file_checks AS (
  SELECT
    (SELECT COUNT(*) FROM actual_files) AS actual_file_count,
    (
      SELECT COUNT(*)
      FROM actual_files AS actual
      LEFT ANTI JOIN expected_files AS expected
        ON actual.file_name = expected.file_name
    ) AS unexpected_file_count,
    (
      SELECT COUNT(*)
      FROM expected_files AS expected
      LEFT ANTI JOIN actual_files AS actual
        ON expected.file_name = actual.file_name
    ) AS missing_file_count
)
SELECT
  actual_file_count,
  unexpected_file_count,
  missing_file_count,
  ASSERT_TRUE(actual_file_count = 7, 'source folder must contain exactly seven CSV files') AS file_count_check,
  ASSERT_TRUE(unexpected_file_count = 0, 'source folder contains an unexpected CSV file') AS unexpected_file_check,
  ASSERT_TRUE(missing_file_count = 0, 'one or more required source files are missing') AS missing_file_check
FROM file_checks;
