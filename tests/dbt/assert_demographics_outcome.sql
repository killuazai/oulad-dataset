select demographics_key
from {{ ref('dim_demographics') }}
where is_withdrawn <> (final_result = 'Withdrawn')
