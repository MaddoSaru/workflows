WITH
    sor_status AS (
        SELECT
            m.id,
            CASE
                WHEN m.passport_uk_tax IS NULL THEN 'SOR UK Not Active' ELSE
                    'SOR UK Active'
            END AS uk_sor_status,
            CASE
                WHEN m.passport_eu_tax IS NULL THEN 'SOR EU Not Active' ELSE
                    'SOR EU Active'
            END AS eu_sor_status
        FROM merchant_clean AS m
    ),

    insurance_status AS (
        SELECT
            ci.merchant_id,
            CASE
                WHEN ci.merchant_id IS NULL THEN 'Insurance Not Active' ELSE
                    'Insurance Active'
            END AS insurance_status
        FROM client_insurance AS ci
    ),

    service_types AS (
        SELECT
            rf.client_id,
            c.COMPANY 'Client',
            COALESCE (rf.merchant_id, m2.id) AS 'merchant_id',
            sl.FULL_NAME 'service_level',
            DATE(FROM_UNIXTIME(start_date)) AS 'service_start_date',
            DATE(FROM_UNIXTIME(end_date)) AS 'End Date'
        FROM
            rate_filter AS rf
        LEFT JOIN merchant_clean AS m
            ON
                rf.merchant_id = m.id
        LEFT JOIN client AS c
            ON
                rf.client_id = c.id
        LEFT JOIN merchant_clean AS m2
            ON
                c.id = m2.client_id
        LEFT JOIN service_level AS sl
            ON
                rf.service_level_id = sl.id
        WHERE
            (
                end_date IS NULL
                OR DATE(FROM_UNIXTIME(end_date)) > NOW()
            )
        GROUP BY
            rf.client_id,
            rf.merchant_id,
            rf.service_level_id
    )

SELECT
    mc.id,
    mc.salesforce_account_id,
    mc.company AS 'brand',
    c.company AS '3pl',
    uk_sor_status,
    eu_sor_status,
    s_t.service_level,
    s_t.service_start_date,
    COALESCE(in_s.insurance_status, 'Insurance Not Active') AS insurance_status
FROM merchant_clean AS mc
LEFT JOIN client AS c ON mc.client_id = c.id
LEFT JOIN sor_status AS s_s ON mc.id = s_s.id
LEFT JOIN insurance_status AS in_s ON mc.id = in_s.merchant_id
LEFT JOIN service_types AS s_t ON mc.id = s_t.merchant_id
