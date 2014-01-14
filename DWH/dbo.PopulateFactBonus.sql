IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactBonus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactBonus]
GO
CREATE PROCEDURE [dbo].[PopulateFactBonus]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages


-------------------------------------
--
--     Сделка в ИТ-поддержки
--
-------------------------------------

DECLARE @sup_start date = '2012-03-01';

-- рассчет базового бонуса
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	ISNULL(MAX(dimDate.DateKey),-1),
	ISNULL(dimPerson.uid,-1),
	ISNULL(dimIssueType.uid,-1),
	1,
	isnull(qc.multiplier, 0) bonus,
	ji.ID
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
	left outer join emp_quality_coefficient qc on qc.tabnum=dimPerson.TabNum and cg.CREATED between qc.ddateb and dateadd(dd,1,qc.ddatee)
where ji.project=10180 
	and ji.issuetype=33 
	and ji.resolution=1 
	and ji.issuestatus=6
	and cg.CREATED>=@sup_start
	and newvalue='6' and oldvalue='5'
group by ji.id,dimIssueType.uid,dimPerson.uid,qc.multiplier;

-- Изменение бонуса по связанным запросам
UPDATE dbo.factBonus SET bonus = a.new_bonus
FROM (
	SELECT	fb.issueid,  
			isnull(case when count(distinct il.source)-count(distinct declined_dev.id)=0 and count(distinct il.source)>0 then bonus/2 
					when COUNT(distinct authored_dev.id)>0 then bonus*(4+isnull(SUM(len(subtask.summary) - len(replace(subtask.summary,',','')) + 1),0))/2 
					else bonus end,0) new_bonus
	FROM factBonus fb
		join dimPerson on dimPerson.uid=fb.person_uid
		join issuelink il on il.destination=fb.issueid and il.linktype=10010 --il.source - dev
		left outer join jiraissue declined_dev on declined_dev.id=il.source and declined_dev.resolution = 2
		left outer join jiraissue authored_dev on authored_dev.id=il.source and authored_dev.REPORTER=dimPerson.ADName and authored_dev.resolution <> 2
		left outer join issuelink il_dev on il_dev.source=il.source and il_dev.linktype=10000 -- li_dev.destination - subtasks
		left outer join jiraissue subtask on subtask.id=il_dev.destination
	WHERE fb.bonustype_uid = 1
	GROUP BY fb.issueid, fb.bonus
	) a
WHERE a.issueid = factBonus.issueid

-- удалить обращения с установленым CF "Повторное обращение" в "Да"
delete from dbo.factBonus
where exists(select * from dbo.customfieldvalue cfv 
where factBonus.issueid=cfv.ISSUE and cfv.CUSTOMFIELD=10660 and cfv.STRINGVALUE='Да');

-- пятикратное увеличение бонуса за обращения связанные с WMS и Плакущевым Денисом
-- CF "Особые отметки" = "WMS"
UPDATE dbo.factBonus SET bonus = bonus * 5
WHERE EXISTS(SELECT * FROM dbo.customfieldvalue cfv 
WHERE factBonus.issueid=cfv.ISSUE AND cfv.CUSTOMFIELD=11040 AND cfv.STRINGVALUE='WMS');

-- пятикратное увеличение бонуса за обращения с сервисом 'SLA - Выгрузки'
-- с сентября 2013
UPDATE dbo.factBonus SET bonus = bonus * 5
FROM dimDate
WHERE EXISTS(SELECT * FROM dbo.customfieldvalue cfv 
WHERE factBonus.issueid=cfv.ISSUE and dimDate.DateKey=dbo.factBonus.date_uid
		AND cfv.CUSTOMFIELD=10420
		AND cfv.STRINGVALUE='SLA - Выгрузки')
		AND dimDate.FullDate >= '2013-09-01';
		
-- увеличение бонуса в 2.5 раз за обращения с сервисом 'SLA - Сопоставление операторов'
-- с сентября 2013
UPDATE dbo.factBonus SET bonus = bonus * 2.5
FROM dimDate
WHERE EXISTS(SELECT * FROM dbo.customfieldvalue cfv 
WHERE factBonus.issueid=cfv.ISSUE and dimDate.DateKey=dbo.factBonus.date_uid
		AND cfv.CUSTOMFIELD=10420
		AND cfv.STRINGVALUE='SLA - Сопоставление операторов')
		AND dimDate.FullDate >= '2013-09-01';

-- увеличение бонуса в 10 раз за обращения с сервисом 'SLA - Сопоставление операторов'
-- с ноября 2013
UPDATE dbo.factBonus SET bonus = bonus * 10
FROM dimDate
WHERE EXISTS(SELECT * FROM dbo.customfieldvalue cfv 
WHERE factBonus.issueid=cfv.ISSUE and dimDate.DateKey=dbo.factBonus.date_uid
		AND cfv.CUSTOMFIELD=10420
		AND cfv.STRINGVALUE='SLA - Отчетность ОБ')
		AND dimDate.FullDate >= '2013-11-01';

-- расставить коэффициенты качества
update dbo.factBonus set quality=qc.coefficient
from dimDate
join emp_quality_coefficient qc on dimDate.FullDate between qc.ddateb and qc.ddatee
join dimPerson on dimPerson.TabNum=qc.tabnum
where dimDate.DateKey=dbo.factBonus.date_uid and dimPerson.uid=dbo.factBonus.person_uid

-- бонус за выгрузку данных в запросах ОДБК
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,11 bonustype_uid
	,40 bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	join dimPerson on dimPerson.ADname=cg.AUTHOR and dimPerson.Department='Отдел ИТ-поддержки'
	join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10350 
	and ci.oldvalue='10054'
	and dimDate.FullDate > '2013-09-01'
group by ji.id,dimIssueType.uid,dimPerson.uid;


-------------------------------------
--
--           ДЕЖУРСТВО
--
-------------------------------------


-- Рассчет дежурства ИТ-поддержки
-- Дежурство дни
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select	 dimDate.DateKey
		,dimPerson.uid
		,-1
		,12
		,case	when ddate.day_type='Р' and max(ji.ID) is null then 420
				when ddate.day_type='Р' and max(ji.ID) is not null then 600
				when ddate.day_type<>'Р' and max(ji.ID) is null then 1000
				when ddate.day_type<>'Р' and max(ji.ID) is not null then 1500
		end bonus
		,-1
		
from ddate 
join emp_dutyroster dr on ddate.ddate between dr.ddateb and dr.ddatee
left outer join dimDate on dimDate.FullDate = ddate.ddate
left outer join dimPerson on dimPerson.TabNum = dr.person_id
left outer join jiraissue ji on ji.CREATED between	DATEADD(HOUR,9, CONVERT(datetime,ddate.ddate)) and
							DATEADD(SECOND,-1,DATEADD(hour,33, CONVERT(datetime,ddate.ddate)))
						and exists (select*from customfieldvalue cfv 
								where cfv.CUSTOMFIELD = 10550 
									and cfv.STRINGVALUE='Есть'
									and cfv.ISSUE=ji.ID)
						and dimPerson.ADName = ji.REPORTER
						and ji.PROJECT = 10180 -- ИТ-поддержка
WHERE dr.dutytype=1 -- Круглосуточная ТП
group by dimDate.DateKey,dimPerson.uid,ddate.day_type
order by 1

-- Дежурство ворклоги
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select	 dimDate.DateKey
		,dimPerson.uid
		,dimIssue.issuetype_uid
		,13 bonustype_uid
		,sum(case when DATEPART(hour,wl.startdate) >= 9 and  DATEPART(hour,wl.startdate) < 23 then round(wl.timeworked/3600*600,0)
			when DATEPART(hour,wl.startdate) < 9 or  DATEPART(hour,wl.startdate) >= 23 then round(wl.timeworked/3600*1200,0)
		 end) bonus
		,dimIssue.uid 
from ddate 
join emp_dutyroster dr on ddate.ddate between dr.ddateb and dr.ddatee
join jiraworklog wl on wl.startdate between	DATEADD(HOUR,9, CONVERT(datetime,ddate.ddate)) and
						DATEADD(SECOND,-1,DATEADD(hour,33, CONVERT(datetime,ddate.ddate)))
					and exists (select * from jiraissue ji join customfieldvalue cfv on cfv.ISSUE=ji.ID
							where  cfv.CUSTOMFIELD = 10550 and cfv.STRINGVALUE='Есть'
								and ji.PROJECT = 10180 -- ИТ-поддержка
								and ji.ID = wl.issueid)
left outer join dimDate on dimDate.FullDate = ddate.ddate
left outer join dimPerson on dimPerson.ADName=wl.author
left outer join dimIssue on dimIssue.uid = wl.issueid
WHERE dr.dutytype=1 -- Круглосуточная ТП
group by dimDate.DateKey
		,dimPerson.uid
		,dimIssue.issuetype_uid
		,dimIssue.uid

-- Рассчет дежурства Инфраструктуры
-- Дежурство дни
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select	 dimDate.DateKey
		,dimPerson.uid
		,-1
		,14
		,case	when max(wl.ID) is null then 350
				when max(wl.ID) is not null then 500
		end bonus
		,-1
		
from ddate 
join emp_dutyroster dr on ddate.ddate between dr.ddateb and dr.ddatee

left outer join dimDate on dimDate.FullDate = ddate.ddate
left outer join dimPerson on dimPerson.TabNum = dr.person_id
left outer join jiraworklog wl on wl.startdate between	DATEADD(HOUR,9, CONVERT(datetime,ddate.ddate)) and
						DATEADD(SECOND,-1,DATEADD(hour,33, CONVERT(datetime,ddate.ddate)))
					and exists (select * from jiraissue ji join customfieldvalue cfv on cfv.ISSUE=ji.ID
							where  cfv.CUSTOMFIELD = 10550 and cfv.STRINGVALUE='Есть'
								and ji.PROJECT = 10070 -- Инфраструктура
								and ji.ID = wl.issueid)
						and dimPerson.ADName = wl.AUTHOR
WHERE dr.dutytype=2 -- Дежурство ИС
group by dimDate.DateKey,dimPerson.uid,ddate.day_type
order by 1

-- Дежурство ворклоги
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select	 dimDate.DateKey
		,dimPerson.uid
		,dimIssue.issuetype_uid
		,15 bonustype_uid
		,sum(case when DATEPART(hour,wl.startdate) >= 9 and  DATEPART(hour,wl.startdate) < 23 then round(wl.timeworked/3600*500,0)
			when DATEPART(hour,wl.startdate) < 9 or  DATEPART(hour,wl.startdate) >= 23 then round(wl.timeworked/3600*1000,0)
		 end) bonus
		,dimIssue.uid 
from ddate 
join emp_dutyroster dr on ddate.ddate between dr.ddateb and dr.ddatee
join jiraworklog wl on wl.startdate between	DATEADD(HOUR,9, CONVERT(datetime,ddate.ddate)) and
						DATEADD(SECOND,-1,DATEADD(hour,33, CONVERT(datetime,ddate.ddate)))
					and exists (select * from jiraissue ji join customfieldvalue cfv on cfv.ISSUE=ji.ID
							where  cfv.CUSTOMFIELD = 10550 and cfv.STRINGVALUE='Есть'
								and ji.PROJECT = 10070 -- Инфраструктура
								and ji.ID = wl.issueid)
left outer join dimDate on dimDate.FullDate = ddate.ddate
left outer join dimPerson on dimPerson.ADName=wl.author
left outer join dimIssue on dimIssue.uid = wl.issueid
WHERE dr.dutytype=2 -- Дежурство ИС
group by dimDate.DateKey
		,dimPerson.uid
		,dimIssue.issuetype_uid
		,dimIssue.uid

-- Рассчет дежурства Поддержки банка
-- Дежурство дни
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select         dimDate.DateKey
                ,dimPerson.uid
                ,-1
                ,16
                ,2500 bonus
                ,-1
from ddate 
join emp_dutyroster dr on ddate.ddate between dr.ddateb and dr.ddatee
left outer join dimDate on dimDate.FullDate = ddate.ddate
left outer join dimPerson on dimPerson.TabNum = dr.person_id
WHERE dr.dutytype=3 -- Дежурство Поддержки банка
group by dimDate.DateKey,dimPerson.uid,ddate.day_type
order by 1

-------------------------------------
--
--           БОНУС КЦ
--
-------------------------------------

-- Платежи 		- Инцидент
-- Поддержка ПБ - Qiwi-claim
-- Платежи 		- Платеж
-- Платежи 		- Субдилер (по 04/2012 включительно)

-- Расчет бонуса по запросам типа Инцидент
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,2 bonustype_uid
	,COUNT(distinct ji.ID) * 	CASE 
					WHEN MAX(dimDate.DateKey) >= 20120401 
						THEN 10 
						ELSE 4 
					END bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10280 
	and ji.issuetype=32 
	and ji.resolution=1 
	and ji.issuestatus=6
	and newvalue='6'
group by ji.id,dimIssueType.uid,dimPerson.uid;

-- Расчет бонуса по запросам типа Qiwi-claim
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,3 bonustype_uid
	,CASE 
		WHEN MAX(dimDate.DateKey) >= 20120501 
			THEN 20 
			ELSE 10 
		END bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10311 
	and ji.issuetype=52 
	and ji.resolution=1 
	and ji.issuestatus=6
	and newvalue='6'
group by ji.id,dimIssueType.uid,dimPerson.uid;

insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,9 bonustype_uid
	,COUNT(distinct cg.ID) * CASE 
		WHEN MAX(dimDate.DateKey) >= 20120501 
			THEN 4 
			ELSE 2
		END bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=cg.AUTHOR
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10311 
	and ji.issuetype=52 
	and (oldvalue='10028' -- из оформления
		or (oldvalue='10052' and newvalue='10013') -- переписка в анализ
		or (oldvalue='10052' and newvalue='10052')) -- переписка в переписку
group by ji.id,dimIssueType.uid,dimPerson.uid;

-- Расчет бонуса по запросам типа Платеж
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,4 bonustype_uid
	,CASE 
		WHEN MAX(dimDate.DateKey) >= 20120501 
			THEN 20 
			ELSE 10
		END bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10280 
	and ji.issuetype=39 
	and ji.resolution=1 
	and ji.issuestatus=6
	and cg.CREATED>='2012-04-01'
	and newvalue='6'
group by ji.id,dimIssueType.uid,dimPerson.uid;

-- Расчет бонуса по запросам типа Субдилер(платежи)
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,5 bonustype_uid
	,10 bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10280 
	and ji.issuetype=24 
	and ji.resolution=1 
	and ji.issuestatus=6
	and cg.CREATED>='2012-04-01'
	and newvalue='6'
group by ji.id,dimIssueType.uid,dimPerson.uid;

-- Расчет бонуса по запросам типа Овердрафт(платежи)
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,6 bonustype_uid
	,CASE 
		WHEN MAX(dimDate.DateKey) >= 20120501 
			THEN 20 
			ELSE 10
		END bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10280 
	and ji.issuetype=58 
	and ji.resolution=1 
	and ji.issuestatus=6
	and cg.CREATED>='2012-04-01'
	and newvalue='6'
group by ji.id,dimIssueType.uid,dimPerson.uid;
-- Расчет бонуса по запросам типа Консультация(платежи)
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,7 bonustype_uid
	,CASE 
		WHEN MAX(dimDate.DateKey) >= 20120501 
			THEN 20 
			ELSE 10
		END bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10280 
	and ji.issuetype=60 
	and ji.resolution=1 
	and ji.issuestatus=6
	and cg.CREATED>='2012-04-01'
	and newvalue='6'
group by ji.id,dimIssueType.uid,dimPerson.uid;
-- Расчет бонуса по запросам типа Терминалы(платежи)
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,8 bonustype_uid
	,CASE 
		WHEN MAX(dimDate.DateKey) >= 20120501 
			THEN 20 
			ELSE 10
		END bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10280 
	and ji.issuetype=59 
	and ji.resolution=1 
	and ji.issuestatus=6
	and cg.CREATED>='2012-04-01'
	and newvalue='6'
group by ji.id,dimIssueType.uid,dimPerson.uid;
-- Расчет бонуса за выгрузку данных для ОДБК
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,11 bonustype_uid
	,20 bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	join dimPerson on dimPerson.ADname=cg.AUTHOR and dimPerson.Department='Техподдержка ОСМП'
	join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10350 
	and ci.oldvalue='10054'
group by ji.id,dimIssueType.uid,dimPerson.uid;

-------------------------------------
--
--           Проекты
--
-------------------------------------

insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(subpers.uid,ISNULL(pers.uid,-1)) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,10 bonustype_uid
	,ISNULL(SUM(subcfv.NUMBERVALUE),ISNULL(SUM(cfv.NUMBERVALUE),0)) bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	join customfieldvalue cfv on cfv.ISSUE=ji.ID
	
	left outer join issuelink il on il.source=ji.ID and il.linktype=10000
	left outer join jiraissue subji on il.DESTINATION=subji.ID
	left outer join customfieldvalue subcfv on subcfv.ISSUE=subji.ID and subcfv.CUSTOMFIELD=10135
	
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson pers on pers.ADname=ji.assignee
	left outer join dimPerson subpers on subpers.ADname=subji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10140 
	and ji.issuetype=29 
	and ji.resolution=1 
	and newvalue='10009'
	and cfv.CUSTOMFIELD=10135
	
group by ji.id,dimIssueType.uid,pers.uid,subpers.uid;

SET NOCOUNT ON -- turn the annoying messages back on
END

GO

