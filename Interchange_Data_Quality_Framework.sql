/* ============================================================
   INTERCHANGE DATA QUALITY & ANALYSIS PROJECT
   Author: [Your Name]
   Approach: Structured Data Quality Framework
   (Structural -> Completeness -> Uniqueness -> Validity -> Accuracy -> Cleaning)
   ============================================================ */


-- =========================================
-- PHASE 0: FIRST LOOK AT THE DATA
-- =========================================
-- Always eyeball raw data before touching anything.
SELECT * FROM [Sample Interchange Dataset];


-- =========================================
-- PHASE 1: STRUCTURAL CHECK (confirm data types)
-- =========================================
-- Knowing the real column types up front prevents mistakes later
-- (e.g. trying to LTRIM/RTRIM a numeric ID column, or checking date
-- format on a column that was never actually stored as text).
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Sample Interchange Dataset';


-- =========================================
-- PHASE 2: COMPLETENESS (missing / null values)
-- =========================================

-- 2a. Quick aggregate check: is there ANY null anywhere in the table?
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM [Sample Interchange Dataset]
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

-- 2b. Column-wise check: exactly which columns, and how many nulls each?
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
FROM [Sample Interchange Dataset];


-- =========================================
-- PHASE 3: UNIQUENESS (duplicate checks)
-- =========================================

-- 3a. Full-row duplicate check (every column identical)
SELECT *
FROM [Sample Interchange Dataset]
GROUP BY 
    InterChangeID, ReportingDate, CardNumber, AcquirerNetworkGroup,
    Merchant, UsageType, ProductType, SettlementAmount,
    InterchangeRevenue, TransactionCount
HAVING COUNT(*) > 1;

-- 3b. Duplicate check on the presumed primary key (InterChangeID)
SELECT InterChangeID, COUNT(*) AS Cnt
FROM [Sample Interchange Dataset]
GROUP BY InterChangeID
HAVING COUNT(*) > 1;

-- 3c. Duplicate check on a composite key (InterChangeID + ReportingDate)
SELECT 
    InterChangeID,
    ReportingDate,
    COUNT(*) AS DuplicateCount
FROM [Sample Interchange Dataset]
GROUP BY InterChangeID, ReportingDate
HAVING COUNT(*) > 1;

-- 3d. Window function version: tag the exact duplicate rows (actionable,
-- not just a count) so they could be reviewed/removed individually.
WITH Dups AS
(
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                InterChangeID, ReportingDate, CardNumber, AcquirerNetworkGroup,
                Merchant, UsageType, ProductType, SettlementAmount,
                InterchangeRevenue, TransactionCount
            ORDER BY InterChangeID
        ) AS rn
    FROM [Sample Interchange Dataset]
)
SELECT *
FROM Dups
WHERE rn > 1;


-- =========================================
-- PHASE 4: VALIDITY (date checks)
-- =========================================

-- 4a. Null/missing dates
SELECT *
FROM [Sample Interchange Dataset]
WHERE ReportingDate IS NULL;

-- 4b. Format issues: does every value actually convert to a real date?
SELECT *
FROM [Sample Interchange Dataset]
WHERE TRY_CONVERT(date, ReportingDate) IS NULL;


-- =========================================
-- PHASE 5: ACCURACY / BUSINESS RULES
-- =========================================
-- These aren't structural checks -- they're checks based on what we KNOW
-- must be true about this business domain.

-- 5a. Negative amounts should never happen in this context
SELECT *
FROM [Sample Interchange Dataset]
WHERE SettlementAmount < 0 OR InterchangeRevenue < 0;

-- 5b. Missing or blank merchant names (blank string, not just NULL)
SELECT *
FROM [Sample Interchange Dataset]
WHERE Merchant IS NULL OR LTRIM(RTRIM(Merchant)) = '';

-- 5c. Zero or negative transaction counts (a row must represent >=1 real transaction)
SELECT *
FROM [Sample Interchange Dataset]
WHERE TransactionCount <= 0;


-- =========================================
-- PHASE 6: CLEANING
-- =========================================
-- Only run after confirming column types in Phase 1 --
-- do NOT trim numeric/ID columns that aren't actually text.
UPDATE [Sample Interchange Dataset]
SET 
    CardNumber = LTRIM(RTRIM(CardNumber)),
    AcquirerNetworkGroup = LTRIM(RTRIM(AcquirerNetworkGroup)),
    Merchant = LTRIM(RTRIM(Merchant)),
    UsageType = LTRIM(RTRIM(UsageType)),
    ProductType = LTRIM(RTRIM(ProductType));


/* ============================================================
   NEXT: Schema design (Star Schema) + your own analysis angle
   go in a separate file once this data-quality pass is clean.
   ============================================================ */
