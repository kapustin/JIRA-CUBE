IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[calculate_sla_monitor_rc_unact]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[calculate_sla_monitor_rc_unact]
GO
CREATE PROCEDURE [dbo].[calculate_sla_monitor_rc_unact] (@month datetime)
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

declare @ddateb1 datetime, @ddatee1 datetime;
declare @ddateb varchar(20), @ddatee varchar(20);
declare @sql nvarchar(4000);
set dateformat dmy;
	create table #result(date_uid datetime,person_uid varchar(150),issuetype_uid varchar(150),bonustype_uid int,bonus float,issueid bigint);
	while @month<'01.02.2014' begin
	
set @ddateb1=DATEADD(month, DATEDIFF(month, 0, @month), 0)--'01.10.2013';
set @ddatee1=DATEADD(month, DATEDIFF(month, 0, @month)+1, 0);--'01.11.2013';
set @ddateb='"'+cast(datepart(year,@ddateb1)as varchar(4))+'-'+cast(datepart(month,@ddateb1)as varchar(2))+'-'+cast(datepart(day,@ddateb1)as varchar(2))+'"';
set @ddatee='"'+cast(datepart(year,@ddatee1)as varchar(4))+'-'+cast(datepart(month,@ddatee1)as varchar(2))+'-'+cast(datepart(day,@ddatee1)as varchar(2))+'"';

set @sql='select 	  from_unixtime(v.clock)
	, v.subject
	, (select from_unixtime(i.clock) from alerts i where  
		from_unixtime(i.clock) between '+@ddateb+' and '+@ddatee+'
		and i.subject like "rc_unact https server check:OK" 
		and from_unixtime(i.clock) between from_unixtime(v.clock) and '+@ddatee+'
		LIMIT 1)

from alerts v
where from_unixtime(v.clock) between '+@ddateb+' and '+@ddatee+'
             and (v.subject like "rc_unact https server check:PROBLEM")
group by from_unixtime(v.clock)
order by 1 desc';

set @sql='select * from openquery(ZABBIX,'''+@sql+''');'

create table #tmp(starttime datetime, subject varchar(50), endtime datetime);
insert into #tmp
exec sp_executesql @sql;
declare @ti float;

set @ti=(select cast(sum(datediff(SECOND,#tmp.starttime,#tmp.endtime)) as float)/60 as ti from #tmp);
drop table #tmp;

insert into #result
select  	@ddateb1 as date_uid,
		(select owner_info from sla_owner where component_info='Adaptive Server Anywhere - rc_unact') as person_uid,
		-1 as issuetype_uid,
		21 as bonustype_uid,
		isnull((select 0 where 7000*((1-@ti/43200)-0.996)/(1-0.996)<0)
		,7000*((1-@ti/43200)-0.996)/(1-0.996)) as bonus,
		-1 as issueid
		

set @month=dateadd(month,1,@month);
	end
	
	INSERT INTO dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
SELECT
	 ISNULL(dimDate.DateKey,-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,-1 issuetype_uid
	,ISNULL(dimBonusType.uid,-1) bonustype_uid
	,#result.bonus
	,-1
FROM #result
	LEFT OUTER JOIN dimDate ON dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, #result.date_uid))
	LEFT OUTER JOIN dimPerson ON dimPerson.ADname=#result.person_uid
	LEFT OUTER JOIN dimBonusType ON dimBonusType.name = (select sla_type_info+' '+component_info from sla_owner where component_id = 10490 and sla_type=2 ) AND dimBonusType.department='Инфраструктура'
WHERE bonus IS NOT NULL AND bonus <> 0
	
	drop table #result;

SET NOCOUNT ON -- turn the annoying messages back on
END
