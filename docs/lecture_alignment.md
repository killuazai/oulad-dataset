# Week 7 / Day 7 alignment

| Lecture requirement | Repository implementation |
|---|---|
| Layered pipeline | Source → Bronze → Silver → Gold → Analytics → dashboards |
| Validate every layer | Persistent gate immediately after each transformed layer |
| Six DQ dimensions | Completeness, Timeliness/Volume, Validity, transformation Accuracy, Consistency, Uniqueness |
| Accountability | Threshold, severity, owner, timestamp, and run ID on every rule |
| Data-quality dashboard | Weighted score, check pass rate, dimensions, suites, datasets, issues, owners, volume, history |
| Dimensional modeling | Three declared fact grains with conformed dimensions |
| Avoid snowball joins | Direct fact-to-dimension keys and role-playing date views |
| Low cost | Explicit schemas, full refresh for a fixed snapshot, reusable aggregate views |
| Scalable organization | Numbered runners, separated source/tests/dashboard SQL, repository checks |
| Honest interpretation | Known null scores remain warnings; risk is rule-based; Accuracy scope is explicit |

Dashboard sources are refreshed only after the complete validation chain, preventing stale or unvalidated results from being published.
