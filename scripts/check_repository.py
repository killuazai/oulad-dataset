#!/usr/bin/env python3
"""Dependency-free structural checks for the OULAD repository."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "README.md",
    "src/00_setup/01_setup.sql",
    "src/01_bronze/sql/02_bronze_sources.sql",
    "src/02_silver/sql/04_silver_tables.sql",
    "src/03_gold/sql/06_gold_dimensions.sql",
    "src/03_gold/sql/07_gold_facts.sql",
    "src/04_analytics/sql/09_learner_outcomes.sql",
    "src/04_analytics/sql/10_student_engagement.sql",
    "src/04_analytics/sql/11_assessment_performance.sql",
    "src/04_analytics/sql/12_at_risk_students.sql",
    "src/05_data_quality/sql/14_dq_dashboard_views.sql",
    "tests/03_validate_bronze.sql",
    "tests/05_validate_silver.sql",
    "tests/08_validate_gold.sql",
    "tests/13_validate_analytics.sql",
    "oulad-genie-pack/00_prepare_genie_sources.sql",
    "dashboards/business_dashboard.sql",
    "dashboards/data_quality_dashboard.sql",
    "dashboards/BUSINESS_DASHBOARD_REVISION_PROMPT.md",
    "dashboards/DATA_QUALITY_DASHBOARD_REVISION_PROMPT.md",
    "docs/data_model.md",
    "docs/data_quality_methodology.md",
    "docs/validation.md",
)

FULL_RUNNER_TARGETS = (
    "src/00_setup/01_setup.sql",
    "src/01_bronze/sql/02_bronze_sources.sql",
    "tests/03_validate_bronze.sql",
    "src/02_silver/sql/04_silver_tables.sql",
    "tests/05_validate_silver.sql",
    "src/03_gold/sql/06_gold_dimensions.sql",
    "src/03_gold/sql/07_gold_facts.sql",
    "tests/08_validate_gold.sql",
    "src/04_analytics/sql/09_learner_outcomes.sql",
    "src/04_analytics/sql/10_student_engagement.sql",
    "src/04_analytics/sql/11_assessment_performance.sql",
    "src/04_analytics/sql/12_at_risk_students.sql",
    "tests/13_validate_analytics.sql",
    "src/05_data_quality/sql/14_dq_dashboard_views.sql",
    "oulad-genie-pack/00_prepare_genie_sources.sql",
)

SQL_GLOBS = (
    "src/**/*.sql",
    "tests/**/*.sql",
    "queries/**/*.sql",
    "dashboards/**/*.sql",
    "oulad-genie-pack/**/*.sql",
)


def main() -> int:
    errors: list[str] = []

    for relative_path in REQUIRED_FILES:
        if not (ROOT / relative_path).is_file():
            errors.append(f"missing required file: {relative_path}")

    sql_files = sorted(
        {
            path
            for pattern in SQL_GLOBS
            for path in ROOT.glob(pattern)
            if path.is_file()
        }
    )

    for path in sql_files:
        text = path.read_text(encoding="utf-8")
        relative_path = path.relative_to(ROOT)
        if not text.strip():
            errors.append(f"empty SQL file: {relative_path}")
        if re.search(r"\bTODO\b", text, re.IGNORECASE):
            errors.append(f"unfinished TODO marker: {relative_path}")
        if re.search(r"\bSELECT\s+\*\b", text, re.IGNORECASE):
            errors.append(f"unqualified SELECT star: {relative_path}")

    runner = ROOT / "notebooks/00_run_full_pipeline.sql"
    if not runner.is_file():
        errors.append("missing full pipeline runner")
    else:
        runner_text = runner.read_text(encoding="utf-8")
        last_position = -1
        for target in FULL_RUNNER_TARGETS:
            notebook_path = "../" + target.removesuffix(".sql")
            position = runner_text.find(f"%run {notebook_path}")
            if position < 0:
                errors.append(f"full runner does not invoke: {target}")
            elif position <= last_position:
                errors.append(f"full runner target is out of order: {target}")
            last_position = max(last_position, position)

    assessment_sql = ROOT / "src/04_analytics/sql/11_assessment_performance.sql"
    if assessment_sql.is_file():
        text = assessment_sql.read_text(encoding="utf-8")
        for required_column in (
            "scored_submission_count",
            "missing_score_count",
            "score_sum",
            "passed_submission_count",
            "dated_submission_count",
            "late_submission_count",
        ):
            if required_column not in text:
                errors.append(f"assessment controls missing: {required_column}")

    for dashboard in sorted((ROOT / "dashboards").glob("*.lvdash.json")):
        try:
            json.loads(dashboard.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            errors.append(f"invalid dashboard JSON {dashboard.name}: {error}")

    if errors:
        print("Repository checks failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Repository checks passed ({len(sql_files)} SQL files inspected).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
