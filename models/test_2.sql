WITH
    total_insured_brands AS (
        SELECT ci.merchant_id AS insured_brand_id
        FROM client_insurance AS ci
        WHERE
            ci.merchant_id IS NOT NULL
            AND ci.archived = 0
    ),

    latest_label_print_date_by_brand AS (
        SELECT
            s.merchant_id,
            MAX(s.time_bought) AS latest_label_print_date
        FROM shipment AS s
        INNER JOIN merchant_clean AS mc ON s.merchant_id = mc.id
        WHERE s.time_bought >= 1641013200 GROUP BY 1
    ),

    total_active_brands AS (
        SELECT merchant_id AS active_brand_id
        FROM latest_label_print_date_by_brand
        WHERE latest_label_print_date >= UNIX_TIMESTAMP(NOW() - INTERVAL 90 DAY)
    )

SELECT
    t1.active_brand_id,
    t2.insured_brand_id
FROM total_active_brands AS t1
LEFT JOIN total_insured_brands AS t2 ON t1.active_brand_id = t2.insured_brand_id
