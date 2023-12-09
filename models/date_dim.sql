{{ config(materialized="table") }}

with
    date_dimensions_final as (
        select
            row_number() over (order by date_value) as date_id,
            to_date(date_value) as date_value,
            extract(year from date_value) as year,
            extract(month from date_value) as month,
            monthname(date_value) as month_name,
            case
                when extract(dayofweek from date_value) = 0
                then 7
                else extract(dayofweek from date_value)
            end as day_of_week,
            extract(day from date_value) as month_day,
            dayname(date_value) as day_name,
            extract(weekofyear from date_value) as week_of_year,
            date_trunc(week, to_date(date_value)) as start_of_week,
            concat(
                yearofweek(start_of_week), '-W', weekofyear(start_of_week)
            ) as year_week,
            last_day(date_value, week) as end_of_week,
    concat(
                extract(year from date_value), '-M', extract(month from date_value)
            ) as year_month,
    concat(
                extract(year from date_value), '-Q', extract(quarter from date_value)
            ) as year_quarter,
            extract(quarter from date_value) as quarter,
            case
                when (extract(dayofweek from date_value) + 1) in (1, 7)
            then true
                else false
            end as is_weekend,
            case when is_weekend = true then 0 else 1 end as business_day,
                        sum(business_day) over (
            order by date_value rows between unbounded preceding and current row
            ) business_day_running_count
        from
            (
    select dateadd(day, seq4(), '2015-01-01') as date_value
from table(generator(rowcount => 9497))
            ))

select *
from date_dimensions_final