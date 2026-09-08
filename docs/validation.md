# Validation reference

| Order | File | Suite | Main coverage |
|---:|---|---|---|
| 1 | `tests/03_validate_bronze.sql` | BRONZE | Required identifiers, source grains, domains, parsing rescue, and expected volume |
| 2 | `tests/05_validate_silver.sql` | SILVER | Clean grains, parent relationships, positive clicks, and score-null monitoring |
| 3 | `tests/08_validate_gold.sql` | GOLD | Dimension keys, fact grains, direct keys, fact ranges, and enrollment reconciliation |
| 4 | `tests/13_validate_analytics.sql` | ANALYTICS | Output grains, outcome totals, additive assessment controls, metric bounds, enrollment reconciliation, and Silver→Gold→Analytics Accuracy controls |

Every suite persists its result before applying its gate. A critical FAIL calls `ASSERT_TRUE` and stops downstream execution.

Known non-errors:

- `imd_band` may be null.
- Registration and unregistration offsets may be null.
- Exam due offsets may be null.
- The source has 173 missing scores.
- Bronze VLE contains repeated learner-site-day rows that Silver sums to the declared daily grain.

Acceptance after a full run:

- Four suites are present in `genie_latest_check_results`.
- `ACCURACY` checks are stored in the `ANALYTICS` suite.
- Accuracy is MEASURED in `genie_dq_canonical_dimensions`.
- No critical FAIL exists.
- The known score condition is one WARNING, not an imputed PASS.
