-- Name: OULAD Data Quality Dashboard Datasets
-- Purpose: Supply Lakeview/AI-BI dashboard datasets matching the reference layout.
-- Usage: Create one dashboard dataset from each query below.

-- Dataset 1: Current KPI cards
SELECT
    weighted_quality_score_pct AS dq_score_pct,
    source_rows_processed,
    failed_rule_evaluations,
    total_checks,
    passed_checks,
    warning_checks,
    failed_checks,
    critical_failures,
    checks_needing_attention,
    layers_checked,
    datasets_checked,
    last_checked_at
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_overview`;

-- Dataset 2: Six reference quality-dimension tiles
SELECT
    dimension_order,
    dimension_label,
    weighted_quality_score_pct,
    measurement_status,
    total_checks,
    warning_checks,
    failed_checks,
    measurement_note
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_canonical_dimensions`
ORDER BY dimension_order;

-- Dataset 3: Overall DQ trend for the last 12 months
SELECT
    run_date,
    weighted_quality_score_pct AS dq_score_pct,
    total_checks,
    warning_checks,
    failed_checks,
    failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_daily_history`
WHERE run_date >= ADD_MONTHS(CURRENT_DATE(), -12)
ORDER BY run_date;

-- Dataset 4: Current check-status distribution
SELECT
    status,
    COUNT(*) AS check_count
FROM `ftw-week-07`.`05-data-quality`.`genie_latest_check_results`
GROUP BY status
ORDER BY CASE status WHEN 'FAIL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END;

-- Dataset 5: Layer and dataset score matrix
SELECT
    layer,
    dataset_name,
    weighted_quality_score_pct,
    total_checks,
    warning_checks,
    failed_checks,
    failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_dataset_scores`
ORDER BY layer, weighted_quality_score_pct, dataset_name;

-- Dataset 6: Current issue drill-down table
SELECT
    status,
    severity,
    layer,
    dataset_name,
    column_name,
    check_name,
    quality_dimension,
    failed_count,
    failure_pct,
    threshold_pct,
    expectation,
    check_owner,
    executed_at
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_problem_areas`
ORDER BY
    CASE status WHEN 'FAIL' THEN 1 ELSE 2 END,
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    failed_count DESC;

-- Dataset 7: Issue ownership summary
SELECT
    check_owner,
    COUNT(*) AS checks_needing_attention,
    COUNT_IF(status = 'FAIL') AS failed_checks,
    COUNT_IF(status = 'WARNING') AS warning_checks,
    SUM(failed_count) AS failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_problem_areas`
GROUP BY check_owner
ORDER BY failed_checks DESC, warning_checks DESC;

-- Dataset 8: Source-volume history
SELECT
    executed_at,
    dataset_name,
    observed_row_count,
    failed_count AS difference_from_baseline,
    status,
    expectation
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_volume_history`
WHERE layer = 'BRONZE'
ORDER BY executed_at, dataset_name;

