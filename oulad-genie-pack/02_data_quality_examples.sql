-- Add each question and its SQL as an example in the Data Quality Genie space.

-- Question: What is the current overall data quality status?
SELECT
    last_checked_at,
    total_checks,
    passed_checks,
    warning_checks,
    failed_checks,
    checks_needing_attention,
    layers_checked,
    datasets_checked,
    weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_overview`;

-- Question: Which current data quality checks need attention?
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
    expectation,
    check_owner
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_problem_areas`
ORDER BY
    CASE status WHEN 'FAIL' THEN 1 ELSE 2 END,
    CASE severity WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
    failed_count DESC;

-- Question: What is the current data quality score for each layer and dataset?
SELECT
    layer,
    dataset_name,
    total_checks,
    passed_checks,
    warning_checks,
    failed_checks,
    weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_dataset_scores`
ORDER BY layer, weighted_quality_score_pct, dataset_name;

-- Question: Which data quality dimensions have the lowest scores?
SELECT
    quality_dimension,
    total_checks,
    warning_checks,
    failed_checks,
    failed_rule_evaluations,
    weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_dimension_scores`
ORDER BY weighted_quality_score_pct, quality_dimension;

-- Question: Which owners have unresolved data quality issues?
SELECT
    check_owner,
    COUNT(*) AS checks_needing_attention,
    COUNT_IF(status = 'FAIL') AS failed_checks,
    COUNT_IF(status = 'WARNING') AS warning_checks,
    SUM(failed_count) AS failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_problem_areas`
GROUP BY check_owner
ORDER BY failed_checks DESC, warning_checks DESC;

-- Question: How has data quality changed over time for each layer?
SELECT
    executed_at,
    layer,
    total_checks,
    warning_checks,
    failed_checks,
    weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_layer_history`
ORDER BY executed_at, layer;

-- Question: Show source volume history and any failed volume checks.
SELECT
    executed_at,
    layer,
    dataset_name,
    check_name,
    observed_row_count,
    failed_count,
    status,
    expectation
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_volume_history`
ORDER BY executed_at, layer, dataset_name;

-- Question: Are there any current critical data quality failures?
SELECT
    layer,
    dataset_name,
    column_name,
    check_name,
    failed_count,
    failure_pct,
    expectation,
    check_owner
FROM `ftw-week-07`.`05-data-quality`.`genie_dq_problem_areas`
WHERE status = 'FAIL'
    AND severity = 'CRITICAL'
ORDER BY failed_count DESC;
