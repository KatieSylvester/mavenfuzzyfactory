/* Maven Fuzzy Factory - Analyzing Website Performance */
SET global time_zone = '-5:00';


/* Find the most-viewed website pages, ranked by session volume */
SELECT
	pageview_url,
    COUNT(DISTINCT website_session_id) AS pvs
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY pvs DESC;

/* Find Top Entry Pages */
WITH first_pageview AS (SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id)
SELECT
	website_pageviews.pageview_url AS landing_page,
	COUNT(DISTINCT first_pageview.website_session_id) AS sessions_hitting_this_lander
FROM first_pageview
	LEFT JOIN website_pageviews
		ON first_pageview.min_pv_id=website_pageviews.website_pageview_id
GROUP BY website_pageviews.pageview_url;

/* Analyze bounce rates and landing page tests */
-- STEP 1: find the first website_pageview for relevant sessions
-- STEP 2: identify the landing page of each session
-- STEP 3: counting pageviews for each session to identify "bounces"
-- STEP 4: summarize total session and bounced sessions by LP

WITH min_pages AS (
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id),
home_landing_page AS (
SELECT 
    min_pages.website_session_id,
	website_pageviews.pageview_url AS landing_page
FROM min_pages
LEFT JOIN website_pageviews
	ON website_pageviews.website_pageview_id=min_pages.min_pageview_id
WHERE website_pageviews.pageview_url = '/home'),
bounced_sessions AS (
SELECT
	home_landing_page.website_session_id,
    home_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM home_landing_page
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = home_landing_page.website_session_id
GROUP BY home_landing_page.website_session_id, home_landing_page.landing_page)
SELECT 
	COUNT(DISTINCT bounced_sessions.website_session_id) AS num_sessions,
    COUNT(DISTINCT CASE WHEN bounced_sessions.count_of_pages_viewed = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    COUNT(DISTINCT CASE WHEN bounced_sessions.count_of_pages_viewed = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT bounced_sessions.website_session_id) AS bounce_rate
FROM bounced_sessions;

/* Analyze landing page tests */
SELECT 
	MIN(created_at) AS first_lander1_date,
    MIN(website_pageview_id) AS first_website_id
FROM website_pageviews
WHERE pageview_url = '/lander-1' AND created_at IS NOT NULL;
-- FIRST LANDER DATE:  2012-06-19 00:35:54
-- FIRST WEBSITE ID:  23504

CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at < '2012-07-28'
	AND website_pageviews.website_pageview_id > 23504
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
GROUP BY website_pageviews.website_session_id;

CREATE TEMPORARY TABLE nonbrand_test_sessions_with_landing_page
SELECT
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home', '/lander-1');


CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT
	nonbrand_test_sessions_with_landing_page.website_session_id,
    nonbrand_test_sessions_with_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM nonbrand_test_sessions_with_landing_page
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = nonbrand_test_sessions_with_landing_page.website_session_id
GROUP BY 
	nonbrand_test_sessions_with_landing_page.website_session_id,
    nonbrand_test_sessions_with_landing_page.landing_page
HAVING count_of_pages_viewed=1;

SELECT
	nonbrand_test_sessions_with_landing_page.landing_page AS landing_page,
    COUNT(DISTINCT nonbrand_test_sessions_with_landing_page.website_session_id) AS total_sessions,
    COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id)/COUNT(DISTINCT nonbrand_test_sessions_with_landing_page.website_session_id) AS bounce_rate
FROM nonbrand_test_sessions_with_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
		ON nonbrand_test_bounced_sessions.website_session_id=nonbrand_test_sessions_with_landing_page.website_session_id
GROUP BY nonbrand_test_sessions_with_landing_page.landing_page;
    

/* LANDING PAGE TREND ANALYSIS */
-- 1 - find website_pageview_id for relevant sessions
-- 2 - identify the landing page of each session
-- 3 - count pageviews to identify bounces
-- 4 - summarize by week

CREATE TEMPORARY TABLE landing_pages
WITH first_pageview AS (
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
LEFT JOIN website_sessions
	ON website_pageviews.website_session_id=website_sessions.website_session_id
WHERE website_pageviews.created_at BETWEEN '2012-06-01' AND '2012-08-31'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY website_session_id)
SELECT 
	first_pageview.website_session_id,
    first_pageview.min_pv_id,
    website_pageviews.created_at,
    pageview_url AS landing_page
FROM first_pageview
	LEFT JOIN website_pageviews
		ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url IN ('/lander-1', '/home');

CREATE TEMPORARY TABLE lander_page_counts
WITH page_counts AS(
SELECT
	website_session_id,
    COUNT(pageview_url) AS page_count
FROM website_pageviews
GROUP BY 1)
SELECT 
	landing_pages.website_session_id,
    landing_pages.created_at,
    landing_pages.landing_page,
    page_counts.page_count
FROM landing_pages
	LEFT JOIN page_counts
    ON landing_pages.website_session_id=page_counts.website_session_id;


SELECT
	-- YEAR(created_at) AS yr,
    -- WEEK(created_at) AS wk,
    MIN(DATE(created_at)) AS week_started,
    (COUNT(DISTINCT CASE WHEN page_count=1 THEN website_session_id ELSE NULL END)*1.0/(COUNT(DISTINCT website_session_id))) AS bounce_rate,
    COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_1_sessions
FROM lander_page_counts
GROUP BY YEAR(created_at), WEEK(created_at);


/* Building Conversion Funnels */
-- build a full conversion funnel from /lander-1 page through thankyou page 
-- since Aug 5
CREATE TEMPORARY TABLE session_made_it_flags2
SELECT 
	website_session_id,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
SELECT
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at AS pageview_created_at,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE 1=1
	AND website_sessions.utm_source='gsearch'
    AND website_sessions.utm_campaign='nonbrand'
    AND website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.created_at) AS pageview_level
GROUP BY website_session_id;

SELECT * FROM session_made_it_flags LIMIT 10;

-- to see counts from each page --
SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it =1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_made_it_flags2;

-- to calculate click rates --
SELECT
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS lander_click_rt,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
    COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt,
    COUNT(DISTINCT CASE WHEN thankyou_made_it =1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS thankyou_click_rt
FROM session_made_it_flags2;


/* Analyzing Conversion Funnel Tests */
SELECT
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS billing_to_order_rt
FROM
	(SELECT
		website_pageviews.website_session_id,
		website_pageviews.pageview_url AS billing_version_seen,
		orders.order_id
	FROM website_pageviews
		LEFT JOIN orders
			ON orders.website_session_id = website_pageviews.website_session_id
	WHERE website_pageviews.website_pageview_id >=53550 
	AND website_pageviews.created_at < '2012-11-10'
	AND website_pageviews.pageview_url IN ('/billing', '/billing-2')) AS billing_with_orders
GROUP BY billing_version_seen;



