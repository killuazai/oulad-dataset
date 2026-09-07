# Engineering decisions

## Databricks SQL and Delta

The reference Instacart project uses Databricks, Delta Lake, and Unity Catalog. This repository keeps that platform so the structure and operating habits transfer directly.

## One configurable catalog and source path

The setup step declares SQL session variables used by all downstream source-format notebooks. This prevents path and catalog values from being duplicated across transformation files.

## Full refresh before incremental complexity

OULAD is a fixed research snapshot, so `CREATE OR REPLACE TABLE` is easier to reason about and test than incremental merge logic. Incremental processing can be introduced later if the source becomes time-varying.

## Separate transformation and validation files

Transformation files create tables; test files persist evidence and decide whether those tables are trustworthy. Runner notebooks always place the test directly after the layer it protects.

## Preserve relative dates

The dataset expresses dates as offsets from presentation start. Integers preserve the source meaning and avoid fabricated calendar values.

## Aggregate repeated daily VLE rows in Silver

The official source contains multiple rows for some learner, VLE site, and day combinations. Bronze preserves and reports those rows. Silver sums their clicks into one conformed daily interaction so the Gold key is stable and unique.

## Deterministic hashed Gold keys

Compound natural keys are hashed to fixed-width Gold keys. Original identifiers remain on facts and dimensions, which keeps debugging straightforward and makes hashes reproducible.

## Conformed dimensions without BI snowball joins

Student, demographics, module presentation, relative date, assessment, and VLE activity are reusable dimensions. Every fact carries its relevant keys directly. Descriptive dimensions never join to other dimensions in the BI model.

## Separate student identity and demographics

The official snapshot contains students whose demographic values differ across enrollments. `dim_student` therefore stores only stable identity, while `dim_demographics` stores a reusable profile. Each fact receives the correct profile from its module-presentation enrollment.

## Persistent quality history

Business data is full-refreshed, but `dq_check_results` is append-only. The dashboard uses evaluated-count-weighted scores rather than averaging check percentages, and critical failures are the only checks that block the pipeline.

## Transparent risk screening

The at-risk output uses documented rules rather than an opaque model. `final_result` is carried only for retrospective analysis and is not part of the risk score. Thresholds must be calibrated and reviewed for fairness before the table informs learner interventions.

## Keep data outside Git

CSV, Parquet, and Delta files are ignored. The repository contains reproducible logic and documentation, while governed datasets stay in the data platform.
