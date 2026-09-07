#!/usr/bin/env python3
"""Dependency-free checks for the OULAD pipeline repository."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "README.md",
    "CONTRIBUTING.md",
    "src/00_setup/01_setup.sql",
    "src/01_bronze/sql/02_bronze_sources.sql",
    "src/02_silver/sql/04_silver_tables.sql",
    "src/03_gold/sql/06_gold_dimensions.sql",
    "src/03_gold/sql/07_gold_facts.sql",
    "src/04_analytics/sql/09_learner_outcomes.sql",
    "src/04_analytics/sql/10_student_engagement.sql",
    "src/04_analytics/sql/11_assessment_performance.sql",
    "src/04_analytics/sql/12_at_risk_students.sql",
    "tests/03_validate_bronze.sql",
    "tests/05_validate_silver.sql",
    "tests/08_validate_gold.sql",
    "tests/13_validate_analytics.sql",
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
)

PRODUCTION_GLOBS = ("src/**/*.sql", "queries/**/*.sql")
FORBIDDEN_PATTERNS = {
    "unqualified SELECT star": re.compile(r"\bSELECT\s+\*\b", re.IGNORECASE),
    "unfinished TODO marker": re.compile(r"\bTODO\b", re.IGNORECASE),
}


def main() -> int:
    errors: list[str] = []

    for relative_path in REQUIRED_FILES:
        if not (ROOT / relative_path).is_file():
            errors.append(f"missing required file: {relative_path}")

    production_files = sorted(
        path
        for pattern in PRODUCTION_GLOBS
        for path in ROOT.glob(pattern)
        if path.is_file()
    )

    seen_numbers: dict[int, Path] = {}
    for path in sorted(ROOT.glob("src/**/*.sql")):
        match = re.match(r"(\d+)_", path.name)
        if not match:
            errors.append(f"production SQL is not numbered: {path.relative_to(ROOT)}")
            continue
        number = int(match.group(1))
        if number in seen_numbers:
            errors.append(
                "duplicate production step number "
                f"{number}: {seen_numbers[number].relative_to(ROOT)} and {path.relative_to(ROOT)}"
            )
        seen_numbers[number] = path

    for path in production_files:
        text = path.read_text(encoding="utf-8")
        relative_path = path.relative_to(ROOT)
        if not text.strip():
            errors.append(f"empty SQL file: {relative_path}")
            continue
        for label, pattern in FORBIDDEN_PATTERNS.items():
            if pattern.search(text):
                errors.append(f"{label} in {relative_path}")

    full_runner = ROOT / "notebooks/00_run_full_pipeline.sql"
    if not full_runner.is_file():
        errors.append("missing full pipeline runner: notebooks/00_run_full_pipeline.sql")
    else:
        runner_text = full_runner.read_text(encoding="utf-8")
        for target in FULL_RUNNER_TARGETS:
            notebook_path = "../" + target.removesuffix(".sql")
            if f"%run {notebook_path}" not in runner_text:
                errors.append(f"full pipeline runner does not invoke: {target}")

    if errors:
        print("Repository checks failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Repository checks passed ({len(production_files)} SQL files inspected).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
