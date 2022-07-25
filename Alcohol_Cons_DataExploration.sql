/*===================================================================================
Alcohol Consumption(2010-2019) Data Exploration


Visualization:
https://public.tableau.com/app/profile/jerry.jheng/viz/AlcoholConsumptionDataExploration/AlcoholConsumptionByLocation

Data source:
https://www.who.int/data/gho/data/indicators/indicator-details/GHO/alcohol-recorded-per-capita-(15-)-consumption-(in-litres-of-pure-alcohol)
====================================================================================*/
CREATE DATABASE `alcohol_consumption`;
USE `alcohol_consumption`;
-- SHOW TABLES;

SELECT *
FROM `alcohol_data`;

SELECT Location, Period, Dim1 AS alcohol_type, FactValueForMeasure AS Litres
FROM `alcohol_data`
ORDER BY Location, Period;


-- -----Check whether there is duplicate data-----
SELECT COUNT(*) AS repetitions, Location, Period, Dim1
FROM `alcohol_data`
GROUP BY Location, Period, Dim1
HAVING repetitions > 1;
-- OR 
WITH `duplicates` AS(SELECT *,
row_number() OVER(
PARTITION BY Location, Period, Dim1
) row_num
FROM alcohol_consumption.alcohol_data )
SELECT * 
FROM `duplicates`
WHERE row_num>1;

SELECT DISTINCT *
FROM `alcohol_data`;

CREATE TABLE `al_tmp` 
SELECT DISTINCT Location, Period, Dim1, FactValueForMeasure
FROM `alcohol_data`;

SELECT COUNT(*) AS repetitions, Location, Period, Dim1
FROM `al_tmp`
GROUP BY Location, Period, Dim1
HAVING repetitions > 1;

SELECT Location, Period, Dim1 as "Alcohol Types", FactValueForMeasure as litres
FROM `al_tmp`;


-- -----Show alcohol consumption after 2010-----

SELECT Location, Period, Dim1 AS alcohol_type, FactValueForMeasure AS Litres
FROM `al_tmp`
WHERE Period >= 2010 AND Dim1 LIKE 'Beer'
ORDER BY Location, Period;


-- -----locations that consume the most beer/wine/spirits/other in the year 2011-----

SELECT *, RANK() OVER (partition by Period, Dim1 order by FactValueForMeasure desc) 
AS `RANK` FROM alcohol_consumption.al_tmp WHERE Dim1="Beer" AND Period="2011" LIMIT 10;

SELECT Location, FactValueForMeasure AS "Beer", 
-- SELECT Location, FactValueForMeasure AS "Wine", 
	@rc := @rc +1 AS count,
	@r :=CASE
	WHEN @rt = FactValueForMeasure THEN @r
    WHEN @rt := FactValueForMeasure THEN @rc
    END AS `rank`
FROM `al_tmp`, (SELECT @rc :=0, @rt :=NULL, @r :=0) b
WHERE Period= 2011 AND Dim1 ="Beer"
-- WHERE Period= 2011 AND Dim1 ="Wine"
ORDER BY FactValueForMeasure DESC LIMIT 10;


-- -----Create a table to put data of beer/wine/.. in same rows-----

CREATE TABLE `al_data`
WITH `All_types` AS (
	SELECT Location, Period, Dim1, FactValueForMeasure AS Total
	FROM `al_tmp`
	WHERE Dim1 LIKE "All types" AND Period >= 2010
	GROUP BY Location, Period
	),
`Beer` AS (
	SELECT Location AS bLocation, Period AS bPeriod, 
			Dim1 AS bDim1, FactValueForMeasure AS Beer
	FROM `al_tmp`
	WHERE Dim1 LIKE "Beer" AND Period >= 2010
	GROUP BY Location, Period
	),
`Wine` AS (
	SELECT Location AS wLocation, Period AS wPeriod, 
			Dim1 AS wDim1, FactValueForMeasure AS Wine
	FROM `al_tmp`
	WHERE Dim1 LIKE "Wine" AND Period >= 2010
	GROUP BY Location, Period
	),
`Spirits` AS (
	SELECT Location AS sLocation, Period AS sPeriod, 
			Dim1 AS sDim1, FactValueForMeasure AS Spirits
	FROM `al_tmp`
	WHERE Dim1 LIKE "Spirits" AND Period >= 2010
	GROUP BY Location, Period
	), 
`Other_alcoholic_beverages` AS (
	select Location AS oLocation, Period AS oPeriod, 
			Dim1 AS oDim1, FactValueForMeasure AS Other_alcoholic_beverages
	FROM `al_tmp`
	WHERE Dim1 LIKE "Other alcoholic beverages" AND Period >= 2010
	GROUP BY Location, Period)
SELECT *
FROM `All_types`
INNER JOIN `Beer`
	ON  All_types.Location= Beer.bLocation 
	AND All_types.Period= Beer.bPeriod
INNER JOIN `Wine`
	ON  All_types.Location= Wine.wLocation 
	AND  All_types.Period = Wine.wPeriod
INNER JOIN `Spirits`
	ON  All_types.Location= Spirits.sLocation 
		AND  All_types.Period = Spirits.sPeriod
INNER JOIN `Other_alcoholic_beverages`
	ON  All_types.Location= Other_alcoholic_beverages.oLocation 
    AND All_types.Period = Other_alcoholic_beverages.oPeriod;

-- SHOW TABLES;


-- -----Percentage of total that people consume beer/wine/spirits/other-----

SELECT Location, Period, 
	Total as "Total (litres)", Beer as "Beer (litres)",
	Wine as "Wine (litres)", Spirits as "Spirits (litres)",
	Other_alcoholic_beverages as "Other alcoholic beverages (litres)",
    (Beer/Total)*100 AS "Beer (%)", (Wine/Total)*100 AS "Wine (%)",
    (Spirits/Total)*100 AS "Spirits (%)", 
    (Other_alcoholic_beverages/Total)*100 AS "Other alcoholic beverages (%)"
FROM `al_data`
ORDER BY 1,2 ASC;

ALTER TABLE al_data
ADD COLUMN PercentageBeer DOUBLE
,ADD COLUMN PercentageSpirits DOUBLE
,ADD COLUMN PercentageWine DOUBLE
,ADD COLUMN PercentageOtherAlcoholicBeverages DOUBLE;

SELECT * FROM al_data;
UPDATE al_data
SET PercentageBeer= (Beer/Total)*100,
	PercentageSpirits=(Spirits/Total)*100,
    PercentageWine=(Wine/Total)*100,
    PercentageOtherAlcoholicBeverages=(Other_alcoholic_beverages/Total)*100;
-- The most consumed beverage type each year in the contries from 2010 to 2019

WITH `no_all_2` AS (
WITH `no_all` AS (SELECT *
FROM `al_tmp`
WHERE Dim1 != 'All types' AND Period >= 2010)
SELECT Location, Period, Max(FactValueForMeasure) AS MF
FROM `no_all` GROUP BY Location, Period
),
`no_all` AS (SELECT Dim1 as "the Most Consumed", Location, Period, FactValueForMeasure AS litres
FROM `al_tmp`
WHERE Dim1 != 'All types' AND Period >= 2010)
SELECT *
FROM `no_all_2`
LEFT JOIN `no_all`
	ON no_all_2.Location=no_all.Location 
	AND no_all_2.Period=no_all.Period 
	AND MF=no_all.litres
    WHERE MF>0;
    
    
-- -----RANKING of particular beverage type (litres) of locations in a particular year-----
-- "All types" OR "Beer" OR "Spirits" OR "Other alcoholic beverages" 

USE alcohol_consumption;
WITH `rank` AS (
SELECT *, rank() over (partition by Period, Dim1 order by FactValueForMeasure desc) as `RANK` from `al_tmp` WHERE Dim1="Beer" AND Period="2011"
)
SELECT * FROM `rank`
HAVING Location="Poland";
SELECT * FROM al_data;

-- AS a function
delimiter //
CREATE FUNCTION RankCheck(Loc VARCHAR(50), Typ VARCHAR(50), Per INT(4))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE c INT;
    WITH `loc_filter` AS(
    WITH `rank` AS (
	SELECT *, rank() over (partition by Period, Dim1 order by FactValueForMeasure desc) as `RANK` 
    FROM `al_tmp` WHERE Dim1=Typ AND Period=Per
	)
	SELECT Location, `RANK` FROM `rank`
	HAVING Location=Loc
    )
    SELECT `RANK` FROM `loc_filter`
    INTO c;
    RETURN c; 
    END
// delimiter ;

-- DROP FUNCTION IF EXISTS RankCheck;
SELECT RankCheck("Poland","Beer",2011);
SELECT RankCheck("Poland","All types",2013);

-- -----RANKING of Beer/Total of locations in a particular year-----
WITH `rank` AS (
SELECT *, rank() over (partition by Period, Dim1 order by PercentageBeer desc) as `RANK` from `al_data` WHERE Period="2011"
)
SELECT * FROM `rank`
HAVING Location="Samoa";
SELECT * FROM al_data;

