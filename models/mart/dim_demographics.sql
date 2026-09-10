{{ config(alias='dim_demographics') }}

select distinct
  sha2(
    concat_ws(
      '||',
      coalesce(gender, 'UNKNOWN'),
      coalesce(region, 'UNKNOWN'),
      coalesce(highest_education, 'UNKNOWN'),
      coalesce(imd_band, 'UNKNOWN'),
      coalesce(age_band, 'UNKNOWN'),
      coalesce(disability, 'UNKNOWN'),
      coalesce(final_result, 'UNKNOWN')
    ),
    256
  ) as demographics_key,
  gender,
  region,
  highest_education,
  imd_band,
  age_band,
  disability,
  final_result,
  cast(final_result = 'Withdrawn' as boolean) as is_withdrawn
from {{ source('oulad_clean', 'student_info_clean') }}
