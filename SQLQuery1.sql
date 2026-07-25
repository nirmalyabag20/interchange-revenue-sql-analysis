-- *INTERCHANGE DATA QUALITY & ANALYSIS PROJECT*
-- ============================================================

USE InterchangeAnalytics;
--Approach: Structured Data Quality Framework (Structural -> Completeness -> Uniqueness -> Validity -> Accuracy -> Cleaning)

--PHASE(0) FIRST LOOK AT THE DATA
SELECT * FROM Sample_Interchange_Dataset;

--PHASE(1): STRUCTURAL(CHECK DATATYPES) 
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Sample_Interchange_Dataset';

--PHASE(2): COMPLETENESS(CHECK MISSING/ NULL VALUES)
--1.Null check
SELECT 
	CASE 
		WHEN EXISTS (	
			SELECT 1 FROM Sample_Interchange_Dataset
			WHERE 
				InterChangeID IS NULL OR
				ReportingDate IS NULL OR
				CardNumber IS NULL OR 
				AcquirerNetworkGroup IS NULL OR 
				Merchant IS NULL OR
				UsageType IS NULL OR
				ProductType IS NULL OR
				SettlementAmount IS NULL OR 
				InterchangeRevenue IS NULL OR
				TransactionCount IS NULL
	)
			THEN 'NULLS Found'
			ELSE 'NO NULLS Found'
	END AS NullCheck;

--2.Null check Column-wise
SELECT
SUM(CASE WHEN InterChangeID IS NULL THEN 1 ELSE 0 END) AS Null_InterChangeID,
SUM(CASE WHEN ReportingDate IS NULL THEN 1 ELSE 0 END) AS Null_ReportingDate,
SUM(CASE WHEN CardNumber IS NULL THEN 1 ELSE 0 END) AS Null_CardNumber,
SUM(CASE WHEN AcquirerNetworkGroup IS NULL THEN 1 ELSE 0 END) AS Null_AcquirerNetworkGroup,
SUM(CASE WHEN Merchant IS NULL THEN 1 ELSE 0 END) AS Null_Merchant,
SUM(CASE WHEN UsageType IS NULL THEN 1 ELSE 0 END) AS Null_UsageType,
SUM(CASE WHEN ProductType IS NULL THEN 1 ELSE 0 END) AS Null_ProductType,
SUM(CASE WHEN SettlementAmount IS NULL THEN 1 ELSE 0 END) AS Null_SettlementAmount,
SUM(CASE WHEN InterchangeRevenue IS NULL THEN 1 ELSE 0 END) AS Null_InterchangeRevenue,
SUM(CASE WHEN TransactionCount IS NULL THEN 1 ELSE 0 END) AS Null_TransactionCount
FROM Sample_Interchange_Dataset;

--PHASE(3): UNIQUENESS(DUPLICATE CHECK)
--1.Full-row duplicate check
SELECT * FROM Sample_Interchange_Dataset 
GROUP BY 
		InterChangeID,
		ReportingDate,
		CardNumber,
		AcquirerNetworkGroup,
		Merchant,
		UsageType,
		ProductType,
		SettlementAmount,
		InterchangeRevenue,
		TransactionCount
HAVING COUNT(*) > 1;
--2.Duplicate check on the presumed primary key (InterChangeID)
SELECT InterChangeID, COUNT(*) AS cnt FROM Sample_Interchange_Dataset
GROUP BY InterChangeID
HAVING COUNT(*) > 1;
--3.Duplicate check on a composite key (InterChangeID + ReportingDate)
SELECT InterChangeID, ReportingDate, COUNT(*) AS Duplicate_cnt FROM Sample_Interchange_Dataset
GROUP BY InterChangeID, ReportingDate
HAVING COUNT(*) > 1;
--4.Identify duplicate rows with ROW_NUMBER()
WITH duplicates AS (
SELECT *, ROW_NUMBER() 
				OVER(PARTITION BY InterChangeID, ReportingDate, CardNumber, AcquirerNetworkGroup,
                Merchant, UsageType, ProductType, SettlementAmount,
                InterchangeRevenue, TransactionCount ORDER BY InterChangeID) AS rnk
FROM Sample_Interchange_Dataset)
SELECT * FROM duplicates WHERE rnk > 1;

--PHASE(4): VALIDITY(Check Invalid/ Null Dates)
--1.Null/missing dates
SELECT * FROM Sample_Interchange_Dataset WHERE ReportingDate IS NULL;
--2.Check Date Format Issues
SELECT * FROM Sample_Interchange_Dataset
WHERE TRY_CONVERT(date, ReportingDate) IS NULL;

--PHASE(5): ACCURACY/ BUSINESS RULES 
--1.Money Field can never be Negative in this context
SELECT * FROM Sample_Interchange_Dataset
WHERE SettlementAmount < 0 OR InterchangeRevenue < 0;
--2.Missing or blank merchant names
SELECT * FROM Sample_Interchange_Dataset
WHERE Merchant IS NULL OR LTRIM(RTRIM(Merchant)) = '';
--3.Zero or negative transaction counts(If a row exist, it must represent atleast one real transaction, Zero would be logically impossible)
SELECT * FROM Sample_Interchange_Dataset
WHERE TransactionCount <= 0;

--PHASE(6): CLEANING
--1.Trim White Spaces
UPDATE Sample_Interchange_Dataset
SET 
	CardNumber = LTRIM(RTRIM(CardNumber)),
    AcquirerNetworkGroup = LTRIM(RTRIM(AcquirerNetworkGroup)),
    Merchant = LTRIM(RTRIM(Merchant)),
    UsageType = LTRIM(RTRIM(UsageType)),
    ProductType = LTRIM(RTRIM(ProductType)
);

--#1 for revenue concentration
---------------------------------

--Q1: Total revenue by merchant, ranked highest to lowest
SELECT Merchant, CAST(ROUND(SUM(InterchangeRevenue), 2) AS DECIMAL(18,2)) AS TotalRevenue 
FROM Sample_Interchange_Dataset
GROUP BY Merchant 
ORDER BY TotalRevenue DESC;

--Q2: % of total revenue per merchant, and cumulative %
WITH MerchantRevenue AS (
    SELECT Merchant, SUM(InterchangeRevenue) AS TotalRevenue 
    FROM Sample_Interchange_Dataset
    GROUP BY Merchant
)
SELECT Merchant, TotalRevenue,
    CAST(TotalRevenue * 100.0 / SUM(TotalRevenue) OVER() AS DECIMAL(5,2)) AS PctOfTotal,
    CAST(SUM(TotalRevenue) OVER (ORDER BY TotalRevenue DESC) * 100.0 
        / SUM(TotalRevenue) OVER () AS DECIMAL(5,2)) AS CumulativePct
FROM MerchantRevenue 
ORDER BY TotalRevenue DESC;

--Q3: Same concentration check, but for cards
WITH CardRevenue AS (
    SELECT CardNumber, SUM(InterchangeRevenue) AS TotalRevenue 
    FROM Sample_Interchange_Dataset
    GROUP BY CardNumber
)
SELECT CardNumber, TotalRevenue,
    CAST(TotalRevenue * 100.0 / SUM(TotalRevenue) OVER() AS DECIMAL(5,2)) AS PctOfTotal,
    CAST(SUM(TotalRevenue) OVER (ORDER BY TotalRevenue DESC) * 100.0 
        / SUM(TotalRevenue) OVER () AS DECIMAL(5,2)) AS CumulativePct
FROM CardRevenue 
ORDER BY TotalRevenue DESC;

--Q4: % of revenue lost if top 3 merchants left
WITH MerchantRevenue AS (
    SELECT Merchant, SUM(InterchangeRevenue) AS TotalRevenue
    FROM Sample_Interchange_Dataset
    GROUP BY Merchant
),
Top3 AS (
    SELECT TOP 3 Merchant, TotalRevenue
    FROM MerchantRevenue
    ORDER BY TotalRevenue DESC
),
GrandTotal AS (
    SELECT SUM(TotalRevenue) AS OverallTotal FROM MerchantRevenue
)
SELECT 
    (SELECT SUM(TotalRevenue) FROM Top3) AS Top3Revenue,
    GrandTotal.OverallTotal,
    CAST((SELECT SUM(TotalRevenue) FROM Top3) * 100.0 / GrandTotal.OverallTotal AS DECIMAL(5,2)) AS PctOfTotalLostIfTop3Left
FROM GrandTotal;

--#2 for PIN vs PINLESS economics
---------------------------------

--Q1: Interchange rate comparison — PIN vs PINLESS
SELECT UsageType,
    ROUND(SUM(SettlementAmount), 2) AS TotalSettlement,
    ROUND(SUM(InterchangeRevenue), 2) AS TotalRevenue,
    CAST(SUM(InterchangeRevenue) * 100.0 / SUM(SettlementAmount) AS DECIMAL(5,3)) AS InterchangeRatePct
FROM Sample_Interchange_Dataset
GROUP BY UsageType;

--Q2: Check if ProductType is evenly distributed across UsageType (avoid a confound)
SELECT UsageType, ProductType, COUNT(*) AS TxnCount,
    SUM(SettlementAmount) AS TotalSettlement,
    SUM(InterchangeRevenue) AS TotalRevenue
FROM Sample_Interchange_Dataset
GROUP BY UsageType, ProductType
ORDER BY UsageType, ProductType;

--#3 for card/customer segmentation
---------------------------------

--Q1: Per-card behavior — distinct merchants used, total revenue, total transactions
SELECT CardNumber,
    COUNT(DISTINCT Merchant) AS DistinctMerchants,
    SUM(InterchangeRevenue) AS TotalRevenue,
    SUM(TransactionCount) AS TotalTransactions
FROM Sample_Interchange_Dataset
GROUP BY CardNumber
ORDER BY TotalRevenue DESC;

--Q2: Segment cards by merchant breadth, then compare average revenue per segment
WITH CardBehavior AS (
    SELECT CardNumber,
        COUNT(DISTINCT Merchant) AS DistinctMerchants,
        SUM(InterchangeRevenue) AS TotalRevenue,
        SUM(TransactionCount) AS TotalTransactions
    FROM Sample_Interchange_Dataset
    GROUP BY CardNumber
)
SELECT 
    CASE 
        WHEN DistinctMerchants <= 5 THEN 'Loyal'
        WHEN DistinctMerchants <= 15 THEN 'Moderate'
        ELSE 'Broad'
    END AS Segment,
    COUNT(*) AS CardsInSegment,
    CAST(AVG(TotalRevenue) AS DECIMAL(10,2)) AS AvgRevenuePerCard,
    CAST(AVG(TotalTransactions) AS DECIMAL(10,2)) AS AvgTransactionsPerCard
FROM CardBehavior
GROUP BY 
    CASE 
        WHEN DistinctMerchants <= 5 THEN 'Loyal'
        WHEN DistinctMerchants <= 15 THEN 'Moderate'
        ELSE 'Broad'
    END
ORDER BY AvgRevenuePerCard DESC;

--#4 for network comparison
---------------------------------

--Q1: Revenue and interchange rate by network
SELECT AcquirerNetworkGroup,
    SUM(SettlementAmount) AS TotalSettlement,
    SUM(InterchangeRevenue) AS TotalRevenue,
    CAST(SUM(InterchangeRevenue) * 100.0 / SUM(SettlementAmount) AS DECIMAL(5,3)) AS InterchangeRatePct
FROM Sample_Interchange_Dataset
GROUP BY AcquirerNetworkGroup;

--Q2: Check if ProductType is evenly distributed across networks (avoid a confound)
SELECT AcquirerNetworkGroup, ProductType, 
    COUNT(*) AS TxnRows,
    SUM(SettlementAmount) AS TotalSettlement,
    SUM(InterchangeRevenue) AS TotalRevenue
FROM Sample_Interchange_Dataset
GROUP BY AcquirerNetworkGroup, ProductType
ORDER BY AcquirerNetworkGroup, ProductType;
