/* Maven Fuzzy Factory */

/* Finding top traffic sources */
SELECT
	utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS number_of_sessions
FROM website_sessions
WHERE  created_at < '2012-04-12'
GROUP BY 
	utm_source, 
    utm_campaign,
    http_referer
ORDER BY number_of_sessions DESC;

/* Analyze Traffice Source Conversion Rates */
SELECT
    COUNT(DISTINCT ws.website_session_id) AS number_of_sessions,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE 
	ws.created_at < '2012-04-14'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';
    
/* Traffic Source Trending */
SELECT
    -- YEAR(created_at) AS yr,
    -- WEEK(created_at) AS wk,
    MIN(DATE(created_at)) AS week_started,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE 
	created_at < '2012-05-10'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at), WEEK(created_at);

/* Bid optimization for paid traffic */
SELECT
	ws.device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id=o.website_session_id
WHERE 
	ws.created_at < '2012-05-11' AND
    utm_source = 'gsearch' AND
    utm_campaign='nonbrand'
GROUP BY ws.device_type;


/* Tranding w/ Granular Segments */
SELECT
	-- YEAR(created_at) AS yr,
    -- WEEK(created_at) AS wk,
	MIN(DATE(created_at)) AS week_started,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions
FROM website_sessions
WHERE 
	created_at BETWEEN '2012-04-15' AND '2012-06-09'
    AND utm_source = 'gsearch'
    AND utm_campaign='nonbrand'
GROUP BY YEAR(created_at), WEEK(created_at);







