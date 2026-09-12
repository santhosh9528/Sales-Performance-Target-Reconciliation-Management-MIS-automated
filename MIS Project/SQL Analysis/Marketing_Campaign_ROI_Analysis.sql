USE integrated_business;

-- ============================================================
-- PART 14 - MARKETING CAMPAIGN & ROI ANALYSIS
-- ============================================================
-- Covers:
-- Marketing Spend
-- Leads
-- Conversions
-- Conversion Rate
-- Revenue
-- CAC
-- ROI
-- Channel Comparison
-- Campaign Type Analysis
-- Region Analysis
-- Monthly Trend
-- Highest Revenue vs Highest Profit Contribution
-- Low Performing Campaigns
-- Management Summary
-- ============================================================


-- ============================================================
-- RESULT 1: OVERALL MARKETING KPI SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS Total_Campaigns,

    ROUND(SUM(Campaign_Spend), 2) AS Total_Marketing_Spend,

    SUM(Leads) AS Total_Leads,

    SUM(Conversions) AS Total_Conversions,

    ROUND(
        SUM(Conversions) * 100.0 /
        NULLIF(SUM(Leads), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(SUM(Revenue), 2) AS Total_Revenue,

    ROUND(
        SUM(Campaign_Spend) /
        NULLIF(SUM(Conversions), 0),
        2
    ) AS CAC,

    ROUND(
        SUM(Revenue) - SUM(Campaign_Spend),
        2
    ) AS Net_Marketing_Contribution,

    ROUND(
        (
            SUM(Revenue) - SUM(Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(Campaign_Spend), 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data;


-- ============================================================
-- RESULT 2: CHANNEL PERFORMANCE
-- ============================================================

SELECT
    Channel,

    COUNT(*) AS Campaign_Count,

    ROUND(
        SUM(Campaign_Spend),
        2
    ) AS Marketing_Spend,

    SUM(Leads) AS Leads,

    SUM(Conversions) AS Conversions,

    ROUND(
        SUM(Conversions) * 100.0 /
        NULLIF(SUM(Leads), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        SUM(Revenue),
        2
    ) AS Revenue,

    ROUND(
        SUM(Campaign_Spend) /
        NULLIF(SUM(Conversions), 0),
        2
    ) AS CAC,

    ROUND(
        SUM(Revenue) - SUM(Campaign_Spend),
        2
    ) AS Net_Contribution,

    ROUND(
        (
            SUM(Revenue) - SUM(Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(Campaign_Spend), 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

GROUP BY Channel

ORDER BY
    ROI_Pct DESC;


-- ============================================================
-- RESULT 3: CAMPAIGN TYPE PERFORMANCE
-- ============================================================

SELECT
    Campaign_Type,

    COUNT(*) AS Campaign_Count,

    ROUND(
        SUM(Campaign_Spend),
        2
    ) AS Marketing_Spend,

    SUM(Leads) AS Leads,

    SUM(Conversions) AS Conversions,

    ROUND(
        SUM(Conversions) * 100.0 /
        NULLIF(SUM(Leads), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        SUM(Revenue),
        2
    ) AS Revenue,

    ROUND(
        SUM(Campaign_Spend) /
        NULLIF(SUM(Conversions), 0),
        2
    ) AS CAC,

    ROUND(
        SUM(Revenue) - SUM(Campaign_Spend),
        2
    ) AS Net_Contribution,

    ROUND(
        (
            SUM(Revenue) - SUM(Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(Campaign_Spend), 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

GROUP BY Campaign_Type

ORDER BY
    ROI_Pct DESC;


-- ============================================================
-- RESULT 4: REGION-WISE MARKETING PERFORMANCE
-- ============================================================

SELECT
    m.Region_ID,

    COALESCE(
        r.Region_Name,
        'Unmapped Region'
    ) AS Region_Name,

    COUNT(*) AS Campaign_Count,

    ROUND(
        SUM(m.Campaign_Spend),
        2
    ) AS Marketing_Spend,

    SUM(m.Leads) AS Leads,

    SUM(m.Conversions) AS Conversions,

    ROUND(
        SUM(m.Conversions) * 100.0 /
        NULLIF(SUM(m.Leads), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        SUM(m.Revenue),
        2
    ) AS Revenue,

    ROUND(
        SUM(m.Revenue) - SUM(m.Campaign_Spend),
        2
    ) AS Net_Contribution,

    ROUND(
        (
            SUM(m.Revenue) - SUM(m.Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(m.Campaign_Spend), 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data m

LEFT JOIN region_master r
    ON m.Region_ID = r.Region_ID

GROUP BY
    m.Region_ID,
    r.Region_Name

ORDER BY
    Revenue DESC;


-- ============================================================
-- RESULT 5: MONTHLY MARKETING TREND
-- ============================================================

SELECT
    DATE_FORMAT(
        Campaign_Month,
        '%Y-%m'
    ) AS Campaign_Month,

    COUNT(*) AS Campaign_Count,

    ROUND(
        SUM(Campaign_Spend),
        2
    ) AS Marketing_Spend,

    SUM(Leads) AS Leads,

    SUM(Conversions) AS Conversions,

    ROUND(
        SUM(Conversions) * 100.0 /
        NULLIF(SUM(Leads), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        SUM(Revenue),
        2
    ) AS Revenue,

    ROUND(
        SUM(Revenue) - SUM(Campaign_Spend),
        2
    ) AS Net_Contribution,

    ROUND(
        (
            SUM(Revenue) - SUM(Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(Campaign_Spend), 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

GROUP BY
    DATE_FORMAT(
        Campaign_Month,
        '%Y-%m'
    )

ORDER BY
    Campaign_Month;


-- ============================================================
-- RESULT 6: INDIVIDUAL CAMPAIGN PERFORMANCE
-- ============================================================

SELECT
    Campaign_ID,
    Campaign_Month,
    Channel,
    Campaign_Type,
    Region_ID,

    ROUND(
        Campaign_Spend,
        2
    ) AS Campaign_Spend,

    Leads,

    Conversions,

    ROUND(
        Conversions * 100.0 /
        NULLIF(Leads, 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        Revenue,
        2
    ) AS Revenue,

    ROUND(
        Campaign_Spend /
        NULLIF(Conversions, 0),
        2
    ) AS CAC,

    ROUND(
        Revenue - Campaign_Spend,
        2
    ) AS Net_Contribution,

    ROUND(
        (
            Revenue - Campaign_Spend
        ) * 100.0 /
        NULLIF(Campaign_Spend, 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

ORDER BY
    ROI_Pct DESC;


-- ============================================================
-- RESULT 7: TOP 10 CAMPAIGNS BY ROI
-- ============================================================

SELECT
    Campaign_ID,
    Campaign_Month,
    Channel,
    Campaign_Type,
    Region_ID,

    ROUND(
        Campaign_Spend,
        2
    ) AS Campaign_Spend,

    Leads,
    Conversions,

    ROUND(
        Conversions * 100.0 /
        NULLIF(Leads, 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        Revenue,
        2
    ) AS Revenue,

    ROUND(
        Revenue - Campaign_Spend,
        2
    ) AS Net_Contribution,

    ROUND(
        (
            Revenue - Campaign_Spend
        ) * 100.0 /
        NULLIF(Campaign_Spend, 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

ORDER BY
    ROI_Pct DESC

LIMIT 10;


-- ============================================================
-- RESULT 8: BOTTOM 10 CAMPAIGNS BY ROI
-- ============================================================

SELECT
    Campaign_ID,
    Campaign_Month,
    Channel,
    Campaign_Type,
    Region_ID,

    ROUND(
        Campaign_Spend,
        2
    ) AS Campaign_Spend,

    Leads,
    Conversions,

    ROUND(
        Conversions * 100.0 /
        NULLIF(Leads, 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        Revenue,
        2
    ) AS Revenue,

    ROUND(
        Revenue - Campaign_Spend,
        2
    ) AS Net_Contribution,

    ROUND(
        (
            Revenue - Campaign_Spend
        ) * 100.0 /
        NULLIF(Campaign_Spend, 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

ORDER BY
    ROI_Pct ASC

LIMIT 10;


-- ============================================================
-- RESULT 9: HIGHEST REVENUE CHANNEL
-- ============================================================

SELECT
    Channel,

    ROUND(
        SUM(Revenue),
        2
    ) AS Total_Revenue,

    ROUND(
        SUM(Campaign_Spend),
        2
    ) AS Total_Spend,

    ROUND(
        SUM(Revenue) - SUM(Campaign_Spend),
        2
    ) AS Net_Contribution,

    ROUND(
        (
            SUM(Revenue) - SUM(Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(Campaign_Spend), 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

GROUP BY Channel

ORDER BY
    Total_Revenue DESC

LIMIT 1;


-- ============================================================
-- RESULT 10: HIGHEST PROFIT CONTRIBUTION CHANNEL
-- ============================================================
-- Dataset does not contain direct Profit.
-- Therefore:
-- Net Marketing Contribution = Revenue - Campaign Spend
-- is used as the marketing contribution proxy.

SELECT
    Channel,

    ROUND(
        SUM(Revenue),
        2
    ) AS Total_Revenue,

    ROUND(
        SUM(Campaign_Spend),
        2
    ) AS Total_Spend,

    ROUND(
        SUM(Revenue) - SUM(Campaign_Spend),
        2
    ) AS Net_Contribution,

    ROUND(
        (
            SUM(Revenue) - SUM(Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(Campaign_Spend), 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

GROUP BY Channel

ORDER BY
    Net_Contribution DESC

LIMIT 1;


-- ============================================================
-- RESULT 11: HIGHEST ROI CHANNEL
-- ============================================================

SELECT
    Channel,

    ROUND(
        SUM(Campaign_Spend),
        2
    ) AS Total_Spend,

    ROUND(
        SUM(Revenue),
        2
    ) AS Total_Revenue,

    ROUND(
        SUM(Revenue) - SUM(Campaign_Spend),
        2
    ) AS Net_Contribution,

    ROUND(
        (
            SUM(Revenue) - SUM(Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(Campaign_Spend), 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

GROUP BY Channel

ORDER BY
    ROI_Pct DESC

LIMIT 1;


-- ============================================================
-- RESULT 12: CHANNEL REVENUE VS CONTRIBUTION RANKING
-- ============================================================

WITH channel_summary AS
(
    SELECT
        Channel,

        SUM(Revenue) AS Revenue,

        SUM(Campaign_Spend) AS Spend,

        SUM(Revenue) - SUM(Campaign_Spend)
            AS Net_Contribution

    FROM marketing_campaign_data

    GROUP BY Channel
)

SELECT
    Channel,

    ROUND(
        Revenue,
        2
    ) AS Revenue,

    ROUND(
        Spend,
        2
    ) AS Marketing_Spend,

    ROUND(
        Net_Contribution,
        2
    ) AS Net_Contribution,

    DENSE_RANK() OVER (
        ORDER BY Revenue DESC
    ) AS Revenue_Rank,

    DENSE_RANK() OVER (
        ORDER BY Net_Contribution DESC
    ) AS Contribution_Rank,

    CASE
        WHEN
            DENSE_RANK() OVER (
                ORDER BY Revenue DESC
            )
            <
            DENSE_RANK() OVER (
                ORDER BY Net_Contribution DESC
            )
        THEN 'High Revenue - Lower Contribution Rank'

        WHEN
            DENSE_RANK() OVER (
                ORDER BY Revenue DESC
            )
            >
            DENSE_RANK() OVER (
                ORDER BY Net_Contribution DESC
            )
        THEN 'Lower Revenue - Better Contribution Rank'

        ELSE 'Same Rank'
    END AS Performance_Observation

FROM channel_summary

ORDER BY
    Revenue_Rank;


-- ============================================================
-- RESULT 13: LOW ROI / UNDERPERFORMING CAMPAIGNS
-- ============================================================

SELECT
    Campaign_ID,
    Campaign_Month,
    Channel,
    Campaign_Type,
    Region_ID,

    ROUND(
        Campaign_Spend,
        2
    ) AS Campaign_Spend,

    Leads,
    Conversions,

    ROUND(
        Conversions * 100.0 /
        NULLIF(Leads, 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        Revenue,
        2
    ) AS Revenue,

    ROUND(
        Revenue - Campaign_Spend,
        2
    ) AS Net_Contribution,

    ROUND(
        (
            Revenue - Campaign_Spend
        ) * 100.0 /
        NULLIF(Campaign_Spend, 0),
        2
    ) AS ROI_Pct

FROM marketing_campaign_data

WHERE
    (
        Revenue - Campaign_Spend
    ) * 100.0 /
    NULLIF(Campaign_Spend, 0) < 100

ORDER BY
    ROI_Pct ASC;


-- ============================================================
-- RESULT 14: RELATIONSHIP / REGION EXCEPTIONS
-- ============================================================

SELECT
    m.Region_ID,

    COUNT(*) AS Campaign_Count,

    'Region not found in Region Master'
        AS Exception_Reason

FROM marketing_campaign_data m

LEFT JOIN region_master r
    ON m.Region_ID = r.Region_ID

WHERE
    r.Region_ID IS NULL

GROUP BY
    m.Region_ID;


-- ============================================================
-- RESULT 15: MANAGEMENT CHANNEL SUMMARY
-- ============================================================

SELECT
    Channel,

    COUNT(*) AS Campaign_Count,

    ROUND(
        SUM(Campaign_Spend),
        2
    ) AS Marketing_Spend,

    ROUND(
        SUM(Revenue),
        2
    ) AS Revenue,

    ROUND(
        SUM(Revenue) - SUM(Campaign_Spend),
        2
    ) AS Net_Contribution,

    ROUND(
        SUM(Conversions) * 100.0 /
        NULLIF(SUM(Leads), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        SUM(Campaign_Spend) /
        NULLIF(SUM(Conversions), 0),
        2
    ) AS CAC,

    ROUND(
        (
            SUM(Revenue) - SUM(Campaign_Spend)
        ) * 100.0 /
        NULLIF(SUM(Campaign_Spend), 0),
        2
    ) AS ROI_Pct,

    CASE
        WHEN
            (
                SUM(Revenue) - SUM(Campaign_Spend)
            ) * 100.0 /
            NULLIF(SUM(Campaign_Spend), 0) >= 200
        THEN 'Excellent'

        WHEN
            (
                SUM(Revenue) - SUM(Campaign_Spend)
            ) * 100.0 /
            NULLIF(SUM(Campaign_Spend), 0) >= 150
        THEN 'Good'

        WHEN
            (
                SUM(Revenue) - SUM(Campaign_Spend)
            ) * 100.0 /
            NULLIF(SUM(Campaign_Spend), 0) >= 100
        THEN 'Average'
s
        ELSE 'Poor'
    END AS Performance_Status

FROM marketing_campaign_data

GROUP BY Channel

ORDER BY
    ROI_Pct DESC;


-- ============================================================
-- PART 14 COMPLETE
-- ============================================================