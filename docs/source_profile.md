# Source profile

The supplied CSV files were profiled before the Gold model was finalized.

| File | Data rows | Modeled grain |
| --- | ---: | --- |
| `courses.csv` | 22 | Module presentation |
| `assessments.csv` | 206 | Assessment |
| `vle.csv` | 6,364 | VLE site within a module presentation |
| `studentInfo.csv` | 32,593 | Student enrollment in a module presentation |
| `studentRegistration.csv` | 32,593 | Student registration in a module presentation |
| `studentAssessment.csv` | 173,912 | Student assessment submission |
| `studentVle.csv` | 10,655,280 | Source interaction record |

The source has 28,785 distinct students. Seventy-two students have demographic differences across enrollment rows, which is why stable student identity and demographics are separate conformed dimensions.

The assessment source has 173 null scores. They are preserved and monitored because null is an observed source state. Non-null scores are constrained to 0 through 100.

The VLE source has repeated student, module presentation, site, and day combinations. Silver sums `sum_click` across those records, producing 8,459,320 rows at the declared daily fact grain while preserving all 39,605,099 clicks.

No assessment identifier or VLE site reference is orphaned in the supplied snapshot.
