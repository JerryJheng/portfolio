/*===================================================================================
Data cleaning for the project:
Price of Renting an Apartment in Taoyuan City
Data source:
https://plvr.land.moi.gov.tw/DownloadOpenData
====================================================================================*/
CREATE DATABASE RentInTaoyuan;
USE RentInTaoyuan;

/*===================================================================================
Import data and backup
====================================================================================*/
-- -----Import data-----
CREATE TABLE RAW_data(
	District TEXT, TransactionSign TEXT, Address TEXT,
    LandAreaSquareMeter TEXT, TheUseZoning TEXT,
    NonMetropolisLandUseDistrict TEXT, NonMetropolisLandUse TEXT,
    TransactionDate TEXT, TransactionItemAndNumber TEXT, 
    RentFloor TEXT, TotalFloor TEXT, BuildingState TEXT,
    MainUse TEXT, MainBuildingMaterials TEXT, DateOfCompletion TEXT,
    BuildingTotalArea TEXT, Room TEXT, Hall INT NULL, Toilet TEXT,
    Compartmented TEXT, ManagingOrg TEXT, FurnitureProvided TEXT,
    TotalPrice TEXT, NTDperM2 TEXT, BerthCategory TEXT, BerthArea TEXT,
    BerthPrice TEXT, NOTE TEXT, SerialNum TEXT);
-- DROP TABLE RAW_data;
SHOW VARIABLES LIKE "secure_file_priv";
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/HPDT2020S1.csv' 
INTO TABLE RAW_data 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY "\n"
IGNORE 2 ROWS;
-- SELECT * FROM RAW_data;


-- -----Back up-----
DROP TABLE RentData;
CREATE TABLE RentData LIKE RAW_data;
INSERT RentData SELECT * FROM RAW_data;
-- SELECT * FROM RentData;


/*===================================================================================
Data cleaning
====================================================================================*/
-- -----Duplicates checking-----
WITH dup AS(
SELECT SerialNum, row_number() OVER(
PARTITION BY SerialNum
) row_num
FROM RentData
)
SELECT *
FROM dup WHERE row_num>1;


-- -----Convert Null Characters into NULLs-----
UPDATE RentData
SET 	District = IF(LENGTH(trim(District)) <1, NULL, District),
	TransactionSign = IF(LENGTH(trim(TransactionSign)) <1, NULL, TransactionSign),
    	Address = IF(LENGTH(trim(Address)) <1,NULL,Address),
    	LandAreaSquareMeter = IF(LENGTH(trim(LandAreaSquareMeter)) <1, NULL, LandAreaSquareMeter),
	TheUseZoning = IF(LENGTH(trim(TheUseZoning)) <1,NULL ,TheUseZoning),
    	NonMetropolisLandUseDistrict = IF(LENGTH(trim(NonMetropolisLandUseDistrict)) <1,NULL,NonMetropolisLandUseDistrict),
	NonMetropolisLandUse = IF(LENGTH(trim(NonMetropolisLandUse)) <1,NULL,NonMetropolisLandUse),
	TransactionDate = IF(LENGTH(trim(TransactionDate)) <1,NULL,TransactionDate),
	TransactionItemAndNumber=IF(LENGTH(trim(TransactionItemAndNumber)) <1,NULL,TransactionItemAndNumber),
	RentFloor=IF( LENGTH(trim(RentFloor)) <1,NULL,RentFloor),
	TotalFloor=IF(LENGTH(trim(TotalFloor)) <1,NULL,TotalFloor),
	BuildingState=IF(LENGTH(trim(BuildingState)) <1,NULL,BuildingState),
	MainUse=IF(LENGTH(trim(MainUse)) <1,NULL,MainUse),
	MainBuildingMaterials=IF(LENGTH(trim(MainBuildingMaterials)) <1,NULL,MainBuildingMaterials),
	DateOfCompletion=IF(LENGTH(trim(DateOfCompletion)) <1,NULL,DateOfCompletion),
	BuildingTotalArea=IF(LENGTH(trim(BuildingTotalArea)) <1,NULL,BuildingTotalArea),
	Room=IF(LENGTH(trim(Room)) <1, NULL,Room),
    	Hall=IF(LENGTH(trim(Hall)) <1, NULL,Hall),
    	Toilet=IF(LENGTH(trim(Toilet)) <1, NULL,Toilet),
    	Compartmented=IF(LENGTH(trim(Compartmented)) <1, NULL,Compartmented),
    	ManagingOrg=IF(LENGTH(trim(ManagingOrg)) <1, NULL,ManagingOrg),
    	FurnitureProvided=IF(LENGTH(trim(FurnitureProvided)) <1, NULL,FurnitureProvided),
    	TotalPrice=IF(LENGTH(trim(TotalPrice)) <1, NULL,TotalPrice),
    	NTDperM2=IF(LENGTH(trim(NTDperM2)) <1, NULL,NTDperM2),
    	BerthCategory=IF(LENGTH(trim(BerthCategory)) <1, NULL,BerthCategory),
    	BerthArea=IF(LENGTH(trim(BerthArea)) <1, NULL,BerthArea),
    	BerthPrice=IF(LENGTH(trim(BerthPrice)) <1, NULL,BerthPrice),
    	NOTE=IF(LENGTH(trim(NOTE)) <1, NULL,NOTE),
    	SerialNum=IF(LENGTH(trim(SerialNum)) <1, NULL,SerialNum)
        ;
ALTER TABLE RentData
ADD RowNum INT;
SET @r :=0;
UPDATE RentData
SET RowNum = (SELECT @r := @r+1);
SELECT * FROM RentData WHERE RowNum =12;
UPDATE RentData
SET TotalFloor = NULL WHERE RowNum=12;


-- -----Change field types-----
ALTER TABLE RentData
MODIFY COLUMN LandAreaSquareMeter DOUBLE NULL,
MODIFY COLUMN TotalFloor INT NULL,
MODIFY COLUMN BuildingTotalArea DOUBLE NULL,
MODIFY COLUMN Room INT NULL,
MODIFY COLUMN Hall INT NULL,
MODIFY COLUMN Toilet INT NULL,
MODIFY COLUMN TotalPrice INT NULL,
MODIFY COLUMN NTDperM2 DOUBLE NULL,
MODIFY COLUMN BerthArea DOUBLE NULL,
MODIFY COLUMN BerthPrice INT NULL
; 


-- -----Extract BerthNum, BuildingNum from `TransactionItemAndNumber`-----
SELECT * FROM RentData;
SELECT TransactionItemAndNumber, substring_index(TransactionItemAndNumber,"位",-1) FROM RentData;
SELECT TransactionItemAndNumber, substring_index(substring_index(TransactionItemAndNumber,"車",1),"物",-1) FROM RentData;
ALTER TABLE RentData
ADD BerthNum INT, 
ADD BuildingNum INT;
UPDATE RentData
SET BerthNum = substring_index(TransactionItemAndNumber,"位",-1),
	BuildingNum = substring_index(substring_index(TransactionItemAndNumber,"車",1),"物",-1);


-- -----Populate NTD per squared meter-----
UPDATE RentData
SET NTDperM2 = IF(NTDperM2 IS NULL,TotalPrice/BuildingTotalArea,NTDperM2);

-- -----Populate NULLs in `NonMetropolisLandUseDistrict` with "Metropolis District"-----
UPDATE RentData
SET NonMetropolisLandUseDistrict = IF(NonMetropolisLandUseDistrict IS NULL,'Metropolis District',NonMetropolisLandUseDistrict);


-- -----Change Chinese characters into arabic numerals in `RentFloor`-----
SELECT Rentfloor,substring_index(Rentfloor,"層",1)
FROM RentData;

DROP FUNCTION ChOne2Ten;
SELECT ChOne2Ten("二");

delimiter // 
CREATE FUNCTION ChOne2Ten(Charac VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE c INT;
    SELECT(CASE WHEN Charac ="一" THEN 1
		 WHEN Charac ="二" THEN 2
         WHEN Charac ="三" THEN 3
         WHEN Charac ="四" THEN 4
         WHEN Charac ="五" THEN 5
         WHEN Charac ="六" THEN 6
         WHEN Charac ="七" THEN 7
         WHEN Charac ="八" THEN 8
         WHEN Charac ="九" THEN 9
         WHEN Charac ="十" THEN 10
    END) INTO c;
    RETURN c;
    END
// 

//
-- SELECT Ch2NumIN99("五十");
-- DROP FUNCTION Ch2NumIN99//
CREATE FUNCTION Ch2NumIN99(Charac VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE c INT;
    SELECT(CASE WHEN LENGTH(Charac)/3=1 
			THEN (SELECT ChOne2Ten(Charac))
		WHEN LENGTH(Charac)/3 = 2 
			THEN (SELECT (CASE WHEN LEFT(Charac,1)="十" 
						THEN 10+(SELECT ChOne2Ten(RIGHT(Charac,1)))
					   WHEN RIGHT(Charac,1)="十"
						THEN (SELECT (ChOne2Ten(LEFT(Charac,1))))*10
					   END ))
         	WHEN LENGTH(Charac)/3 = 3 
			THEN (SELECT ChOne2Ten(Left(Charac,1)))*10+ ChOne2Ten(RIGHT(Charac,1))
    		END) INTO c;
    RETURN c;
 END  //
 delimiter ;

SELECT * FROM RentData;
ALTER TABLE RentData
ADD RentFloorINT INT;
-- ALTER TABLE RentData
-- DROP COLUMN RentFloorINT;

-- SELECT Rentfloor, Ch2NumIN99(substring_index(Rentfloor,"層",1))
-- FROM RentData;

CREATE TABLE a
SELECT Address,RowNum,Rentfloor, Ch2NumIN99(substring_index(Rentfloor,"層",1)) AS FloorINT
FROM RentData;
-- DROP TABLE a;
-- SELECT * FROM a;

-- SHOW TABLES;
-- USE rentintaoyuan;
SELECT RentData.RowNum, RentData.RentFloor, a.FloorINT
FROM RentData
JOIN a
ON RentData.Address = a.Address AND RentData.RowNum = a.RowNum;
-- SHOW VARIABLES LIKE "%timeout";

UPDATE RentData
JOIN a 
	ON RentData.Address = a.Address AND RentData.RowNum = a.RowNum
SET RentData.RentFloorINT = a.FloorINT;
-- DROP TABLE a

-- -----Extract Year, Convert field type into DATE-----
SELECT * FROM RentData;
-- Check whether there are NULLs
SELECT * FROM RentData WHERE TransactionDate IS NULL;
-- LANDs do not have DateOfCompletion
SELECT * FROM RentData WHERE DateOfCompletion IS NULL AND BuildingNum!=0; 

SELECT TransactionDate, DateOfCompletion, RIGHT(TransactionDate,4), RIGHT(DateOfCompletion,4),
	CAST(LEFT(TransactionDate,LENGTH(TransactionDate)-4)AS decimal)+1911 AS TransactionYear, CAST(LEFT(DateOfCompletion,LENGTH(DateOfCompletion)-4)AS decimal)+1911 AS BuiltYear,
    CONCAT(CAST(LEFT(TransactionDate,LENGTH(TransactionDate)-4)AS decimal)+1911,RIGHT(TransactionDate,4)) AS TransactionDateNew,
     CONCAT(CAST(LEFT(DateOfCompletion,LENGTH(DateOfCompletion)-4)AS decimal)+1911,RIGHT(DateOfCompletion,4)) AS BuiltDate
FROM RentData;

 ALTER TABLE RentData
 ADD TransactionYear INT NULL, 
 ADD BuiltYear INT NULL, ADD TransactionDateNew DATE NULL, ADD BuiltDate DATE NULL;
/*
ALTER TABLE RentData
MODIFY COLUMN TransactionYear INT NULL,
MODIFY COLUMN BuiltYear INT NULL,
MODIFY COLUMN TransactionDateNew DATE NULL,
MODIFY COLUMN BuiltDate DATE NULL;
*/
UPDATE RentData
SET TransactionYear = CAST(LEFT(TransactionDate,LENGTH(TransactionDate)-4)AS decimal)+1911,
BuiltYear = CAST(LEFT(DateOfCompletion,LENGTH(DateOfCompletion)-4)AS decimal)+1911,
 TransactionDateNew = CONCAT(CAST(LEFT(TransactionDate,LENGTH(TransactionDate)-4)AS decimal)+1911,RIGHT(TransactionDate,4)),
 BuiltDate=CONCAT(CAST(LEFT(DateOfCompletion,LENGTH(DateOfCompletion)-4)AS decimal)+1911,RIGHT(DateOfCompletion,4));


-- -----Change 有/無 into Yes/No-----
SELECT * FROM rentintaoyuan.RentData;
UPDATE RentData
SET Compartmented = replace(Compartmented,"有","Yes"),
	Compartmented = replace(Compartmented,"無","No"),
    ManagingOrg = replace(ManagingOrg,"有","Yes"),
	ManagingOrg = replace(ManagingOrg,"無","No"),
    FurnitureProvided = replace(FurnitureProvided,"有","Yes"),
	FurnitureProvided = replace(FurnitureProvided,"無","No");
    

-- -----Extract LiftOrNot-----
SELECT DISTINCT BuildingState
FROM RentData;

SELECT DISTINCT BuildingState, LiftOrNot
FROM RentData;

ALTER TABLE RentData
ADD LiftOrNot TEXT;

UPDATE RentData SET LiftOrNot = "Yes" WHERE BuildingState= "住宅大樓(11層含以上有電梯)";

UPDATE RentData SET LiftOrNot = "Yes" WHERE BuildingState= "華廈(10層含以下有電梯)";

UPDATE RentData SET LiftOrNot = "No" WHERE BuildingState= "公寓(5樓含以下無電梯)";

UPDATE RentData SET LiftOrNot ="Not Sure" WHERE LiftOrNot IS NULL;


-- ---Extract Social housing-----
ALTER TABLE RentData
ADD SocialHousing TEXT;

UPDATE RentData 
SET SocialHousing = if(Note LIKE "%社會%","Yes","No");

-- -----AgeOfBuilding-----
ALTER TABLE RentData
ADD AgeOfBuilding INT NULL;
UPDATE RentData
SET AgeOfBuilding = (TransactionYear-BuiltYear);


-- -----Data screening and Create View-----
CREATE VIEW rentdata_view AS
SELECT *,RowNum, Address, District, NonMetropolisLandUseDistrict, AgeOfBuilding,
		TransactionYear, TransactionDateNew, BuiltYear, BuiltDate, BuildingTotalArea,
		RentFloorINT AS Floor, TotalFloor, BerthNum, BuildingNum,
        Room, Hall,Toilet, ManagingOrg,FurnitureProvided, LiftOrNot
		TotalPrice, NTDperM2 AS PricePerSquareMeter, Socialhousing
FROM rentintaoyuan.RentData
WHERE 
BuildingNum>0 AND (BuildingState !="透天厝") AND (BuildingState !="店面(店鋪)") AND (BuildingState !="辦公商業大樓") 
AND (BuildingState !="工廠") AND (BuildingState !="倉庫") AND (BuildingState !="廠辦")
AND (MainUse !="小型社區式日間照顧及重建服務場所") AND (MainUse!="農舍") AND (MainUse NOT LIKE"%辦公室%") AND (MainUse!="工業用") 
;

-- -----Table for correlation matrix-----
/*
[Code book]

District: 
"中壢區" 0; "八德區" 1; "大園區" 2; "大溪區" 3;
"平鎮區" 4; "新屋區" 5; "桃園區" 6; "楊梅區" 7;
"蘆竹區" 8; "觀音區" 9; "龍潭區" 10; "龜山區" 11;

UsingZone:
"Metropolis District" 0"; 特定農業區" 1; "工業區" 2; 
"一般農業區" 3; "鄉村區" 4; "特定專用區" 5; "山坡地保育區" 6.

Yes/No/Not Sure =0/1/2
*/
-- USE rentinyuan;
-- DROP TABLE RentData4Corr;
CREATE TABLE RentData4corr (
		RowNum INT NULL, Address TEXT, District TEXT, UsingZone TEXT, AgeOfBuilding INT NULL,
		TransactionYear INT NULL, TransactionDate DATE, BuiltYear INT NULL, BuiltDate DATE, BuildingTotalArea DOUBLE NULL,
		Floor INT NULL, TotalFloor INT NULL, BerthNum INT NULL, BuildingNum INT NULL,
        Room INT NULL, Hall INT NULL,Toilet INT NULL, ManagingOrg TEXT,FurnitureProvided TEXT, Lift TEXT,
		TotalPrice INT NULL, PricePerSquareMeter DOUBLE NULL, Socialhousing TEXT
);
INSERT RentData4corr
SELECT RowNum, Address, District, NonMetropolisLandUseDistrict, AgeOfBuilding,
		TransactionYear, TransactionDateNew, BuiltYear, BuiltDate, BuildingTotalArea,
		RentFloorINT AS Floor, TotalFloor, BerthNum, BuildingNum,
        Room, Hall,Toilet, ManagingOrg,FurnitureProvided, LiftOrNot,
		TotalPrice, NTDperM2 AS PricePerSquareMeter, Socialhousing
FROM rentintaoyuan.RentData
WHERE 
BuildingNum>0 AND (BuildingState !="透天厝") AND (BuildingState !="店面(店鋪)") AND (BuildingState !="辦公商業大樓") AND (BuildingState !="工廠") AND (BuildingState !="倉庫") AND (BuildingState !="廠辦")
AND (MainUse !="小型社區式日間照顧及重建服務場所") AND (MainUse!="農舍") AND (MainUse NOT LIKE"%辦公室%") AND (MainUse!="工業用"); 
-- SELECT * FROM RentData4Corr;


-- Code `District`
SELECT DISTINCT District FROM RentData4corr; 
UPDATE RentData4corr
SET District= (SELECT DistCode(District));
SELECT DistCode("觀音區");

delimiter // 
CREATE FUNCTION DistCode(Charac VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE c INT;
    SELECT(CASE WHEN Charac ="中壢區" THEN 0
		 WHEN Charac ="八德區" THEN 1
         WHEN Charac ="大園區" THEN 2
         WHEN Charac ="大溪區" THEN 3
         WHEN Charac ="平鎮區" THEN 4
         WHEN Charac ="新屋區" THEN 5
         WHEN Charac ="桃園區" THEN 6
         WHEN Charac ="楊梅區" THEN 7
         WHEN Charac ="蘆竹區" THEN 8
         WHEN Charac ="觀音區" THEN 9
         WHEN Charac ="龍潭區" THEN 10
         WHEN Charac ="龜山區" THEN 11
    END) INTO c;
    RETURN c;
    END
// 

delimiter ;


-- Code `UsingZone`
SELECT DISTINCT UsingZone FROM RentData4corr;
UPDATE RentData4corr
SET UsingZone = (SELECT(uzCode(UsingZone)));

delimiter // 
CREATE FUNCTION uzCode(Charac VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE c INT;
    SELECT(CASE WHEN Charac ="Metropolis District" THEN 0
		 WHEN Charac ="特定農業區" THEN 1
         WHEN Charac ="工業區" THEN 2
         WHEN Charac ="一般農業區" THEN 3
         WHEN Charac ="鄉村區" THEN 4
         WHEN Charac ="特定專用區" THEN 5
         WHEN Charac ="山坡地保育區" THEN 6
    END) INTO c;
    RETURN c;
    END
//  delimiter ;

-- Code Y/N/NotSure
UPDATE RentData4corr
SET ManagingOrg = (SELECT ynCode(ManagingOrg)),
	FurnitureProvided = (SELECT ynCode(FurnitureProvided)),
    Socialhousing = (SELECT ynCode(Socialhousing)),
	Lift =(SELECT ynCode(Lift));
-- DROP FUNCTION ynCode;
delimiter // 
CREATE FUNCTION ynCode(Charac VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE c INT;
    SELECT(CASE WHEN Charac ="Yes" THEN 0
		 WHEN Charac ="No" THEN 1
         WHEN Charac ="Not Sure" THEN 2
    END) INTO c;
    RETURN c;
    END
//  delimiter ;
-- SELECT * FROM RentData4corr;
