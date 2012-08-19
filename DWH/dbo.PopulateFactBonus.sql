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

insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	ISNULL(MAX(dimDate.DateKey),-1),
	ISNULL(dimPerson.uid,-1),
	ISNULL(dimIssueType.uid,-1),
	1,
	isnull(case when count(distinct il.source)-count(distinct ji_dev.id)=0 and count(distinct il.source)>0 then qc.multiplier/2 
		when COUNT(distinct ji2.id)>0 then qc.multiplier*(4+COUNT(distinct il_dev.destination))/2 
		else qc.multiplier end,0) bonus,
	ji.ID
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join issuelink il on il.destination=ji.id and il.linktype=10010 --il.source - dev
	left outer join jiraissue ji_dev on ji_dev.id=il.source and ji_dev.resolution = 2
	left outer join jiraissue ji2 on ji2.id=il.source and ji2.REPORTER=ji.assignee
	left outer join issuelink il_dev on il_dev.source=il.source and il_dev.linktype=10000
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



-- удалить обращения с установленым CF "Повторное обращение" в "Да"
delete from dbo.factBonus
where exists(select * from dbo.customfieldvalue cfv 
where factBonus.issueid=cfv.ISSUE and cfv.CUSTOMFIELD=10660 and cfv.STRINGVALUE='Да');

-- расставить коэффициенты качества
update dbo.factBonus set quality=qc.coefficient
from dimDate
join emp_quality_coefficient qc on dimDate.FullDate between qc.ddateb and qc.ddatee
join dimPerson on dimPerson.TabNum=qc.tabnum
where dimDate.DateKey=dbo.factBonus.date_uid and dimPerson.uid=dbo.factBonus.person_uid

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


SET NOCOUNT ON -- turn the annoying messages back on
END

GO

