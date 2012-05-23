IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactPersonStats]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactPersonStats]
GO
CREATE PROCEDURE [dbo].[PopulateFactPersonStats]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

INSERT INTO dbo.factPersonStats (date_uid,person_uid,actual_wh,timetabled_wh,quality)
SELECT	ISNULL(dimDate.DateKey,-1)
		,ISNULL(dimPerson.uid,-1)
		,ROUND(SUM(DATEDIFF(minute,t2.ddatetime,t1.ddatetime))/60.0,2) actual_wh
		,0 timetabled_wh
		,1 quality
FROM
	(SELECT ROW_NUMBER() OVER(PARTITION BY code,ddate ORDER BY ddatetime DESC) AS num, code,ddate, ddatetime
		FROM entrance) t1
	JOIN 
	(SELECT ROW_NUMBER() OVER(PARTITION BY code,ddate ORDER BY ddatetime DESC) AS num, code,ddate, ddatetime
		FROM entrance) t2 ON t1.num=t2.num-1 AND t1.ddate=t2.ddate AND t1.code=t2.code
	LEFT OUTER JOIN dimDate ON dimDate.FullDate=t1.ddate
	LEFT OUTER JOIN dimPerson ON dimPerson.TabNum=t1.code-200000
WHERE t1.num%2<>0
GROUP BY dimPerson.uid,dimDate.DateKey;

MERGE INTO dbo.factPersonStats AS Target
USING (SELECT	ISNULL(dimDate.DateKey,-1) date_uid
				,ISNULL(dimPerson.uid,-1) person_uid
				,qc.coefficient quality
		FROM emp_quality_coefficient qc
		JOIN dimDate ON dimDate.FullDate BETWEEN qc.ddateb AND qc.ddatee
		LEFT OUTER JOIN dimPerson ON dimPerson.TabNum=qc.tabnum) AS Source
		ON Target.date_uid = Source.date_uid AND Target.person_uid = Source.person_uid
WHEN MATCHED THEN
	UPDATE SET quality = Source.quality
WHEN NOT MATCHED BY TARGET THEN
	INSERT (date_uid, person_uid,actual_wh,timetabled_wh,quality) 
		VALUES (date_uid, person_uid,0,0,quality);

SET NOCOUNT ON -- turn the annoying messages back on
END

GO