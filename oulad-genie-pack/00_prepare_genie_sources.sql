-- Name: 00 - Prepare Genie Sources
-- Purpose: Create flat, governed views for two OULAD Genie spaces.
-- Prerequisite: Run the complete OULAD pipeline through analytics validation first.
-- Cost design: Genie queries small aggregate views instead of repeatedly joining facts.

-- BUSINESS ANALYTICS

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.`genie_engagement_outcomes` AS
SELECT
    final_result,
    COUNT(*) AS student_enrollments,
    ROUND(AVG(active_days), 2) AS average_active_days,
    ROUND(AVG(activities_used), 2) AS average_activities_used,
    SUM(total_clicks) AS total_clicks,
    ROUND(AVG(total_clicks), 2) AS average_total_clicks,
    PERCENTILE_APPROX(total_clicks, 0.5) AS median_total_clicks,
    ROUND(AVG(average_clicks_per_active_day), 2) AS average_clicks_per_active_day
FROM `ftw-week-07`.`04-analytics`.`student_engagement`
GROUP BY final_result;

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.`genie_weekly_activity` AS
SELECT
    module.code_module,
    module.code_presentation,
    relative_date.relative_week,
    SUM(interaction.sum_click) AS total_clicks,
    COUNT(DISTINCT interaction.student_key) AS active_students,
    SUM(interaction.student_site_day_count) AS student_site_days,
    COUNT(DISTINCT interaction.site_key) AS activities_used,
    ROUND(
        SUM(interaction.sum_click) / NULLIF(COUNT(DISTINCT interaction.student_key), 0),
        2
    ) AS average_clicks_per_active_student
FROM `ftw-week-07`.`03-mart`.`fact_vle_interaction` AS interaction
INNER JOIN `ftw-week-07`.`03-mart`.`dim_relative_date` AS relative_date
    ON interaction.activity_date_key = relative_date.relative_date_key
INNER JOIN `ftw-week-07`.`03-mart`.`dim_module_presentation` AS module
    ON interaction.module_presentation_key = module.module_presentation_key
GROUP BY
    module.code_module,
    module.code_presentation,
    relative_date.relative_week;

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.`genie_demographic_outcomes` AS
SELECT
    COALESCE(demographic.gender, 'UNKNOWN') AS gender,
    COALESCE(demographic.age_band, 'UNKNOWN') AS age_band,
    COALESCE(demographic.highest_education, 'UNKNOWN') AS highest_education,
    COALESCE(demographic.imd_band, 'UNKNOWN') AS imd_band,
    COUNT(*) AS student_enrollments,
    SUM(enrollment.withdrawn_count) AS withdrawn_students,
    SUM(enrollment.passed_count + enrollment.distinction_count) AS successful_students,
    ROUND(AVG(enrollment.withdrawn_count), 4) AS withdrawal_rate,
    ROUND(
        AVG(enrollment.passed_count + enrollment.distinction_count),
        4
    ) AS successful_outcome_rate,
    ROUND(AVG(enrollment.studied_credits), 2) AS average_studied_credits,
    ROUND(AVG(enrollment.previous_attempts), 2) AS average_previous_attempts
FROM `ftw-week-07`.`03-mart`.`fact_student_enrollment` AS enrollment
INNER JOIN `ftw-week-07`.`03-mart`.`dim_demographics` AS demographic
    ON enrollment.demographics_key = demographic.demographics_key
GROUP BY
    COALESCE(demographic.gender, 'UNKNOWN'),
    COALESCE(demographic.age_band, 'UNKNOWN'),
    COALESCE(demographic.highest_education, 'UNKNOWN'),
    COALESCE(demographic.imd_band, 'UNKNOWN');

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.`genie_risk_summary` AS
SELECT
    code_module,
    code_presentation,
    risk_level,
    CASE risk_level
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END AS risk_level_order,
    COUNT(*) AS student_enrollments,
    COUNT_IF(final_result = 'Withdrawn') AS withdrawn_students,
    COUNT_IF(final_result IN ('Pass', 'Distinction')) AS successful_students,
    ROUND(AVG(risk_score), 2) AS average_risk_score,
    ROUND(AVG(active_days), 2) AS average_active_days,
    ROUND(AVG(total_clicks), 2) AS average_total_clicks,
    ROUND(AVG(average_score), 2) AS average_assessment_score,
    ROUND(AVG(CASE WHEN final_result = 'Withdrawn' THEN 1 ELSE 0 END), 4)
        AS actual_withdrawal_rate
FROM `ftw-week-07`.`04-analytics`.`at_risk_students`
GROUP BY
    code_module,
    code_presentation,
    risk_level;

-- DATA QUALITY
-- Every validator currently generates its own run_id. This view intentionally selects
-- the most recent complete validator run for EACH layer, not one global run_id.

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.`genie_latest_check_results` AS
WITH layer_runs AS (
    SELECT
        layer,
        run_id,
        MAX(executed_at) AS run_executed_at
    FROM `ftw-week-07`.`05-data-quality`.`dq_check_results`
    GROUP BY
        layer,
        run_id
),
ranked_layer_runs AS (
    SELECT
        layer,
        run_id,
        run_executed_at,
        ROW_NUMBER() OVER (
            PARTITION BY layer
            ORDER BY run_executed_at DESC, run_id DESC
        ) AS run_rank
    FROM layer_runs
)
SELECT checks.*
FROM `ftw-week-07`.`05-data-quality`.`dq_check_results` AS checks
INNER JOIN ranked_layer_runs AS latest
    ON checks.layer = latest.layer
    AND checks.run_id = latest.run_id
WHERE latest.run_rank = 1;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.`genie_dq_overview` AS
SELECT
    MAX(executed_at) AS last_checked_at,
    COUNT(*) AS total_checks,
    COUNT_IF(status = 'PASS') AS passed_checks,
    COUNT_IF(status = 'WARNING') AS warning_checks,
    COUNT_IF(status = 'FAIL') AS failed_checks,
    COUNT_IF(status IN ('WARNING', 'FAIL')) AS checks_needing_attention,
    COUNT(DISTINCT layer) AS layers_checked,
    COUNT(DISTINCT CONCAT(layer, '/', dataset_name)) AS datasets_checked,
    SUM(total_count) AS evaluated_values,
    SUM(failed_count) AS failed_rule_evaluations,
    ROUND(
        100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0),
        3
    ) AS weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.`genie_latest_check_results`;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.`genie_dq_dimension_scores` AS
SELECT
    quality_dimension,
    COUNT(*) AS total_checks,
    COUNT_IF(status = 'PASS') AS passed_checks,
    COUNT_IF(status = 'WARNING') AS warning_checks,
    COUNT_IF(status = 'FAIL') AS failed_checks,
    SUM(failed_count) AS failed_rule_evaluations,
    ROUND(
        100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0),
        3
    ) AS weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.`genie_latest_check_results`
GROUP BY quality_dimension;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.`genie_dq_dataset_scores` AS
SELECT
    layer,
    dataset_name,
    COUNT(*) AS total_checks,
    COUNT_IF(status = 'PASS') AS passed_checks,
    COUNT_IF(status = 'WARNING') AS warning_checks,
    COUNT_IF(status = 'FAIL') AS failed_checks,
    SUM(failed_count) AS failed_rule_evaluations,
    ROUND(
        100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0),
        3
    ) AS weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.`genie_latest_check_results`
GROUP BY
    layer,
    dataset_name;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.`genie_dq_problem_areas` AS
SELECT
    executed_at,
    layer,
    dataset_name,
    column_name,
    check_name,
    quality_dimension,
    check_type,
    expectation,
    threshold_pct,
    severity,
    check_owner,
    total_count,
    failed_count,
    failure_pct,
    status
FROM `ftw-week-07`.`05-data-quality`.`genie_latest_check_results`
WHERE status IN ('WARNING', 'FAIL');

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.`genie_dq_layer_history` AS
SELECT
    run_id,
    executed_at,
    layer,
    COUNT(*) AS total_checks,
    COUNT_IF(status = 'PASS') AS passed_checks,
    COUNT_IF(status = 'WARNING') AS warning_checks,
    COUNT_IF(status = 'FAIL') AS failed_checks,
    SUM(failed_count) AS failed_rule_evaluations,
    ROUND(
        100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0),
        3
    ) AS weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.`dq_check_results`
GROUP BY
    run_id,
    executed_at,
    layer;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.`genie_dq_volume_history` AS
SELECT
    run_id,
    executed_at,
    layer,
    dataset_name,
    check_name,
    expectation,
    total_count AS observed_row_count,
    failed_count,
    status
FROM `ftw-week-07`.`05-data-quality`.`dq_check_results`
WHERE check_type = 'VOLUME';
