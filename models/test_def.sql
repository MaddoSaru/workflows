WITH sor_status AS (
	SELECT 
		m.id,
		CASE WHEN m.passport_uk_tax IS NULL THEN 'SOR UK Not Active' ELSE 'SOR UK Active' END AS uk_sor_status,
		CASE WHEN m.passport_eu_tax IS NULL THEN 'SOR EU Not Active' ELSE 'SOR EU Active' END AS eu_sor_status
	FROM merchant_clean m 
),
insurance_status AS (
	SELECT
		ci.merchant_id,
		CASE WHEN ci.merchant_id IS NULL THEN 'Insurance Not Active' ELSE 'Insurance Active' END AS insurance_status
	FROM client_insurance ci 
),
service_types AS (
	 SELECT
		rf.client_id,
		c.company 'Client',
		CASE
			WHEN rf.merchant_id IS NULL THEN m2.id
			ELSE rf.merchant_id
		END 'merchant_id',
		sl.full_name 'service_level',
		DATE(FROM_UNIXTIME(start_date)) 'service_start_date',
		DATE(FROM_UNIXTIME(end_date)) 'End Date'
	FROM
		rate_filter rf
	LEFT JOIN merchant_clean m ON
		m.id = rf.merchant_id
	LEFT JOIN client c ON
		c.id = rf.client_id
	LEFT JOIN merchant_clean m2 ON
		m2.client_id = c.id
	LEFT JOIN service_level sl ON
		sl.id = rf.service_level_id
	WHERE
		(end_date IS NULL
			OR DATE(FROM_UNIXTIME(end_date)) > NOW())
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
	COALESCE(in_s.insurance_status,'Insurance Not Active') AS insurance_status,
	s_t.service_level,
	s_t.service_start_date
FROM merchant_clean mc
LEFT JOIN client c ON mc.client_id = c.id
LEFT JOIN sor_status s_s ON mc.id = s_s.id
LEFT JOIN insurance_status in_s ON mc.id = in_s.merchant_id
LEFT JOIN service_types s_t ON mc.id = s_t.merchant_id