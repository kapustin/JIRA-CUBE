IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactBonusINFR]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactBonusINFR]
GO
CREATE PROCEDURE [dbo].[PopulateFactBonusINFR]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

-------------------------------------
--
--     Сделка ИС
--
-------------------------------------

DECLARE @bonus_start date = '2012-06-01';

insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
        ISNULL(MAX(dimDate.DateKey),-1),
        ISNULL(dimPerson.uid,-1),
        ISNULL(dimIssueType.uid,-1),
        19,
        CASE 
                WHEN (DATEDIFF(dd, MAX(ji.DUEDATE), MAX(cg.CREATED)) <= 0) THEN 50 ELSE -500
        END bonus,
        ji.ID
from jiraissue ji
        join changegroup cg on cg.issueid=ji.id
        join changeitem ci on ci.groupid=cg.id and field='status'
        left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
        left outer join dimPerson on dimPerson.ADname=ji.assignee
        left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10070 
        and ji.issuetype in (32,38) 
        and ji.resolution=1 
        and cg.CREATED>=@bonus_start
        and newvalue='5'
group by ji.id,dimIssueType.uid,dimPerson.uid;

-------------------------------------
--
--     СЛА плюс для ИС
--
-------------------------------------

declare @ddateb datetime, @ddatee datetime, @ddatei datetime,@comp varchar(150), @i int;
set dateformat dmy;
set @ddateb='01.01.2013';
set @ddatee=DATEADD(month, DATEDIFF(month, 0, getdate()+1), 0);
create table #tmp(ddate datetime,person varchar(50),issuetype int,project int,bonus float,issueid bigint,bonustype varchar(150)) 
create table #sla_owner(id int identity(1,1) not null,component_info varchar(150));
insert into #sla_owner(component_info)
select component_info from sla_owner where sla_type=1;
set @ddatei=@ddateb;
while @ddatei<@ddatee begin
	set @i=1;
	while @i<=(select max(id) from #sla_owner) begin
 		set @comp=(select component_info from #sla_owner where id=@i);
		insert into #tmp
		exec calculate_sla_plus @ddatei,@comp;
		set @i=@i+1;
	end
	set @ddatei=dateadd(month,1,@ddatei);
end

INSERT INTO dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
SELECT
	 ISNULL(dimDate.DateKey,-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,ISNULL(dimBonusType.uid,-1) bonustype_uid
	,#tmp.bonus
	,#tmp.issueid
FROM #tmp
	LEFT OUTER JOIN dimDate ON dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, #tmp.ddate))
	LEFT OUTER JOIN dimPerson ON dimPerson.ADname=#tmp.person
	LEFT OUTER JOIN dimIssueType ON dimIssueType.issuetype_id=#tmp.issuetype AND dimIssueType.project_id=#tmp.project
	LEFT OUTER JOIN dimBonusType ON dimBonusType.name = #tmp.bonustype AND dimBonusType.department='Инфраструктура'
WHERE bonus IS NOT NULL AND bonus <> 0

truncate table #tmp;
truncate table #sla_owner;

-------------------------------------
--
--     СЛА минус для ИС
--
-------------------------------------

--declare @ddateb datetime, @ddatee datetime, @ddatei datetime,@comp varchar(150), @i int;
set dateformat dmy;
set @ddateb='01.01.2013';
set @ddatee=DATEADD(month, DATEDIFF(month, 0, getdate()+1), 0);
--create table #tmp(ddate datetime,person varchar(50),issuetype int,project int,bonus float,issueid bigint,bonustype varchar(150)) 
--create table #sla_owner(id int identity(1,1) not null,component_info varchar(150));
insert into #sla_owner(component_info)
select component_info from sla_owner where sla_type=0;
set @ddatei=@ddateb;
while @ddatei<@ddatee begin
	set @i=1;
	while @i<=(select max(id) from #sla_owner) begin
 		set @comp=(select component_info from #sla_owner where id=@i);

		print @comp;
		print @ddatei;

		insert into #tmp
		exec calculate_sla_minus @ddatei,@comp;
		set @i=@i+1;
	end
	set @ddatei=dateadd(month,1,@ddatei);
end

INSERT INTO dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
SELECT
	 ISNULL(dimDate.DateKey,-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,ISNULL(dimBonusType.uid,-1) bonustype_uid
	,#tmp.bonus
	,#tmp.issueid
FROM #tmp
	LEFT OUTER JOIN dimDate ON dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, #tmp.ddate))
	LEFT OUTER JOIN dimPerson ON dimPerson.ADname=#tmp.person
	LEFT OUTER JOIN dimIssueType ON dimIssueType.issuetype_id=#tmp.issuetype AND dimIssueType.project_id=#tmp.project
	LEFT OUTER JOIN dimBonusType ON dimBonusType.name = #tmp.bonustype AND dimBonusType.department='Инфраструктура'
WHERE bonus IS NOT NULL AND bonus <> 0

drop table #tmp;
drop table #sla_owner;

SET NOCOUNT ON -- turn the annoying messages back on
END
