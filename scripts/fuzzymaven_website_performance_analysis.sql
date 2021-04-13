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


-- CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
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
    












