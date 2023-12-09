{{ config(materialized="table") }}

WITH
    date_dimensions_final AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY date_value) AS date_id,
            TO_DATE(date_value) AS date_value,
            EXTRACT(YEAR FROM date_value) AS year,
            EXTRACT(MONTH FROM date_value) AS month,
            MONTHNAME(date_value) AS month_name,
            CASE
                WHEN EXTRACT(DAYOFWEEK FROM date_value) = 0
                    THEN 7
                ELSE EXTRACT(DAYOFWEEK FROM date_value)
            END AS day_of_week,
            EXTRACT(DAY FROM date_value) AS month_day,
            DAYNAME(date_value) AS day_name,
            EXTRACT(WEEKOFYEAR FROM date_value) AS week_of_year,
            DATE_TRUNC(WEEK, TO_DATE(date_value)) AS start_of_week,
            CONCAT(
                YEAROFWEEK(start_of_week), '-W', WEEKOFYEAR(start_of_week)
            ) AS year_week,
            LAST_DAY(date_value, WEEK) AS end_of_week,
            CONCAT(
                EXTRACT(YEAR FROM date_value),
                '-M',
                EXTRACT(MONTH FROM date_value)
            ) AS year_month,
            CONCAT(
                EXTRACT(YEAR FROM date_value),
                '-Q',
                EXTRACT(QUARTER FROM date_value)
            ) AS year_quarter,
            EXTRACT(QUARTER FROM date_value) AS quarter,
            COALESCE ((EXTRACT(DAYOFWEEK FROM date_value) + 1) IN (1, 7),
            FALSE) AS is_weekend,
            CASE WHEN is_weekend = true THEN 0 ELSE 1 END AS business_day,
            SUM(business_day) OVER (
                ORDER BY
                    date_value
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS business_day_running_count
        FROM
            (
                SELECT DATEADD(DAY, SEQ4(), '2015-01-01') AS date_value
                FROM TABLE(GENERATOR(rowcount => 9497))
            )
    )

SELECT *
FROM date_dimensions_final
