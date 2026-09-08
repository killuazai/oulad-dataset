# Engineering decisions

## Databricks SQL, Delta, and Unity Catalog

The project uses the same platform as the reference coursework pipeline. Explicit schemas, Delta tables, and governed schemas keep execution reproducible.

## Fixed snapshot and full refresh

OULAD is a fixed research snapshot. `CREATE OR REPLACE TABLE` is easier to validate than premature incremental logic. Quality results remain append-only for audit and trends.

## Independently runnable files

Each SQL file declares the namespace variables it requires so it can run independently. The source path must remain identical in Setup and Bronze; tests and documentation enforce the configured location.

## Validation after every layer

Transformation and validation remain separate. Bronze, Silver, Gold, and Analytics each have a gate. The Analytics gate also verifies cross-layer transformation Accuracy before dashboard sources refresh; Accuracy is not modeled as a fifth pipeline layer.

## Relative dates and role-playing views

OULAD dates are offsets from presentation start. One physical `dim_relative_date` is reused through five role-playing views; no calendar date is fabricated.

## Daily VLE consolidation

Bronze preserves repeated learner-site-day records. Silver sums their clicks to one learner-site-day grain. Reconciliation proves that click totals are preserved.

## Deterministic keys and direct relationships

SHA-256 keys are reproducible for coursework. Every relevant key is placed directly on each fact, avoiding snowball joins. A production-scale implementation may adopt compact numeric keys if changed consistently everywhere.

## Separate learner identity and demographics

One learner can have different demographic profiles across module presentations. `dim_student` stores identity; `dim_demographics` stores the profile used for the specific enrollment and is linked directly from every fact.

## Accurate aggregate measures

Counts and sums are published as additive controls. Rates are recalculated from those controls. Distinct counts and medians are explicitly non-additive and are not re-aggregated across groups.

## Accuracy boundary

Accuracy means Silver-to-Gold and Gold-to-Analytics control-total reconciliation. External truth cannot be established without an authoritative independent source.

## Transparent risk screening

Risk levels are deterministic coursework rules. `final_result` is retained for retrospective evaluation but does not contribute to risk score. The output is not presented as a trained predictive model.
