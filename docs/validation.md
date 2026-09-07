# Validation

Every validation file both appends check results to `oulad_dq.dq_check_results` and applies a pipeline gate.

| Step | File | Main coverage |
| --- | --- | --- |
| Bronze | `tests/03_validate_bronze.sql` | Required identifiers, uniqueness, accepted values, ranges, schema rescue, published source volume |
| Silver | `tests/05_validate_silver.sql` | Clean grains, referential integrity, positive clicks, score null-rate monitoring |
| Gold | `tests/08_validate_gold.sql` | Dimension uniqueness, direct fact-to-dimension keys, measure ranges, row reconciliation |
| Analytics | `tests/13_validate_analytics.sql` | Reporting grain, metric bounds, enrollment reconciliation |

Critical failures call `ASSERT_TRUE` and stop the Databricks run. A noncritical failure is persisted for investigation but does not block downstream work. See `data_quality_methodology.md` for scoring and status rules.

## Known source conditions

- `imd_band` may be null.
- Registration and unregistration offsets may be null.
- Exam due offsets may be null.
- The official source contains 173 null assessment scores; non-null scores must remain from 0 through 100.
- Bronze `student_vle` contains repeated learner, site, and day combinations. Silver deliberately sums them to one row at the declared Gold fact grain.

These conditions are monitored or explicitly modeled rather than silently imputed.
