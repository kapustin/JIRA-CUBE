IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactPersonStats]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactPersonStats]
GO
CREATE PROCEDURE [dbo].[PopulateFactPersonStats]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages
-- Фактическое время для всех
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

-- качество
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

-- график работы и отработанное время по графику
MERGE INTO dbo.factPersonStats AS Target
USING (select	ISNULL(dimDate.DateKey,-1) date_uid
				,ISNULL(dimPerson.uid,-1) person_uid
				,ISNULL((MAX(sch.min_worktime)/60.0 * CASE WHEN (MAX(day_type)='Р' and MAX(schedule_type_id)=1) or (MAX(schedule_type_id)=2 and datediff(day,MAX(sch.ddateb),MAX(sch.ddate))%4<=1) THEN 1 
											ELSE 0 
											END),0) timetabled_wh
				,ISNULL(ROUND(SUM(DATEDIFF	(minute
							,CASE WHEN datediff(minute,t2.ddate,t2.ddatetime)>=time_start then t2.ddatetime else dateadd(minute,time_start,convert(datetime,t2.ddate)) END
							,CASE WHEN datediff(minute,t1.ddate,t1.ddatetime)<=time_end then t1.ddatetime else dateadd(minute,time_end,convert(datetime,t1.ddate)) END
							))/60.0,2),0) actual_wh
		from (select ROW_NUMBER() OVER(PARTITION BY d.ddate,s.person_id ORDER BY s.priority DESC) rn
					,d.ddate
					,ddateb
					,day_type
					,person_id as tabnum
					,schedule_type_id
					,time_start
					,time_end
					,min_worktime
				from ddate d 
				join emp_schedule s on d.ddate between s.ddateb and isnull(s.ddatee,'9999-12-31')) sch
			left outer JOIN
			(SELECT ROW_NUMBER() OVER(PARTITION BY code,ddate ORDER BY ddatetime DESC) AS num, code,ddate, ddatetime
				FROM entrance) t1 on t1.code-200000=sch.tabnum and t1.ddate=sch.ddate and t1.num%2<>0
			left outer JOIN 
			(SELECT ROW_NUMBER() OVER(PARTITION BY code,ddate ORDER BY ddatetime DESC) AS num, code,ddate, ddatetime
				FROM entrance) t2 ON t1.num=t2.num-1 AND t1.ddate=t2.ddate AND t1.code=t2.code
				LEFT OUTER JOIN dimDate ON dimDate.FullDate = sch.ddate
				LEFT OUTER JOIN dimPerson ON dimPerson.TabNum=sch.tabnum	
		where rn=1
		group by dimDate.DateKey,dimPerson.uid) AS Source
		ON Target.date_uid = Source.date_uid AND Target.person_uid = Source.person_uid
WHEN MATCHED THEN
	UPDATE SET actual_wh=Source.actual_wh, timetabled_wh=Source.timetabled_wh
WHEN NOT MATCHED BY TARGET THEN
	INSERT (date_uid, person_uid,actual_wh,timetabled_wh,quality) 
		VALUES (date_uid, person_uid,Source.actual_wh,Source.timetabled_wh,1);		
	
SET NOCOUNT ON -- turn the annoying messages back on
END

GO