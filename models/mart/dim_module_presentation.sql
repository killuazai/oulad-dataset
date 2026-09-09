{{ config(alias='dim_module_presentation') }}

select
  sha2(concat_ws('||', code_module, code_presentation), 256)
    as module_presentation_key,
  sha2(code_module, 256) as course_key,
  code_module,
  code_presentation,
  cast(substring(code_presentation, 1, 4) as int) as presentation_year,
  substring(code_presentation, 5, 1) as presentation_term,
  case substring(code_presentation, 5, 1)
    when 'B' then 'February start'
    when 'J' then 'October start'
    else 'Other start'
  end as presentation_term_name,
  module_presentation_length
from {{ source('oulad_clean', 'courses_clean') }}
