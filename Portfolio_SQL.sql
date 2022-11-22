USE NgocAnh_Portfolio
GO

-- Business results by month and by year
SELECT
	YEAR(o.[order_date]) AS [Year]
	,MONTH(o.[order_date]) AS [Month]
	,SUM(oi.[quantity]) AS [Output]
	,SUM(oi.[quantity] * oi.[list_price] * (1 - oi.[discount])) AS [Revenue]
FROM [sales].[order_items] oi
LEFT JOIN [sales].[orders] o
	ON oi.[order_id] = o.[order_id]
GROUP BY 
	YEAR(o.[order_date])
	,MONTH(o.[order_date])
ORDER BY [Year], [Month]

-- Show orders with a total net value greater than 20000 on the sales.order_items table
SELECT 
	[order_id]
    ,SUM([quantity] * [list_price] * (1 - [discount])) AS [total_net_value]
FROM [BikeStores].[sales].[order_items]
GROUP BY [order_id]
HAVING SUM([quantity] * [list_price] * (1 - [discount])) > 20000
ORDER BY [total_net_value]


-- List of 3 months with the highest total order value by store and year
WITH get_data
AS
(
    SELECT
        s.[store_name]
        ,YEAR(o.[order_date]) AS [Year]
        ,MONTH(o.[order_date]) AS [Month]
        ,SUM(oi.[quantity]) AS [Output]
        ,SUM(oi.[quantity] * oi.[list_price] * (1 - oi.[discount])) AS [Revenue]
    FROM [sales].[order_items] oi
    JOIN [sales].[orders] o
        ON oi.[order_id] = o.[order_id]
    JOIN [sales].[stores] s 
        ON o.[store_id] = s.[store_id]
    WHERE YEAR(o.[order_date]) IN (2016, 2017, 2018)
    GROUP BY
        s.[store_name]
        ,YEAR(o.[order_date])
        ,MONTH(o.[order_date])
)
, Top3_HighestRevenue_Store_Year
AS
(   
    SELECT
        [store_name]
        ,[Year]
        ,[Month]
        ,[Output]
        ,[Revenue]
        ,DENSE_RANK() OVER (PARTITION BY [store_name], [Year] ORDER BY [Revenue] DESC) AS [ranking]
    FROM get_data
)
SELECT
    [store_name]
    ,[Year]
    ,[Month]
    ,[Output]
    ,[Revenue]
FROM Top3_HighestRevenue_Store_Year
WHERE [ranking] <= 3

-- Business results of each store compared to the same period last year
WITH get_data
AS
(
    SELECT
        s.[store_name]
        ,YEAR(o.[order_date]) AS [Year]
        ,SUM(oi.[quantity]) AS [Output]
        ,SUM(oi.[quantity] * oi.[list_price] * (1 - oi.[discount])) AS [Revenue]
    FROM [sales].[order_items] oi
    JOIN [sales].[orders] o
        ON oi.[order_id] = o.[order_id]
    JOIN [sales].[stores] s 
        ON o.[store_id] = s.[store_id]
    WHERE YEAR(o.[order_date]) IN (2016, 2017, 2018)
    GROUP BY
        s.[store_name]
        ,YEAR(o.[order_date])
)
, SamePeriodLastYear
AS 
(
    SELECT
        [store_name]
        ,[Year]
        ,[Output]
        ,[Revenue]
        ,LAG([Revenue]) OVER (PARTITION BY [store_name] ORDER BY [Year]) AS [same_period_last_year_TNV]
    FROM get_data
)
SELECT
    [store_name]
    ,[Year]
    ,[Output]
    ,[Revenue]
    ,[same_period_last_year_TNV]
    ,[diff_between_same_period_last_year_TNV] = [Revenue] - [same_period_last_year_TNV] 
FROM SamePeriodLastYear
ORDER BY 
    [store_name]
    ,[Year]