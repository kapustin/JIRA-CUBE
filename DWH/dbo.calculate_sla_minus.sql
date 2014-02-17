IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[calculate_sla_minus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[calculate_sla_minus]
GO
CREATE PROCEDURE [dbo].[calculate_sla_minus](@month datetime,@component varchar(150))
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

declare @ddateb datetime, @ddatee datetime, @dcomponent nvarchar(150), @sla_type int;
set dateformat dmy;
set @ddateb=DATEADD(month, DATEDIFF(month, 0, @month), 0)--'01.10.2013';
set @ddatee=DATEADD(month, DATEDIFF(month, 0, @month)+1, 0);--'01.11.2013';
set @dcomponent=@component;--'Рабочие станции';
set @sla_type=0;

select 
        dbo.jiraissue.id,
        dbo.jiraissue.issuetype,
        dbo.jiraissue.PROJECT,
        dbo.jiraissue.priority,
        (select STRINGVALUE from dbo.customfieldvalue where customfield=10510 and issue=dbo.jiraissue.id) as Otv,
        dbo.jiraissue.created,
        dbo.component.id as component
        
into #sla_issue 
from dbo.jiraissue
join dbo.nodeassociation on dbo.nodeassociation.SOURCE_NODE_ID=dbo.jiraissue.id
join dbo.component on dbo.component.id=dbo.nodeassociation.SINK_NODE_ID
where 
dbo.jiraissue.issuetype=32 and -- Инцидент
dbo.component.cname=@dcomponent and dbo.nodeassociation.ASSOCIATION_TYPE='IssueComponent'and 
isnull(dbo.jiraissue.resolution,0)<>2

select #sla_issue.id, dbo.changegroup.created as ddate, cast(newvalue as varchar) as state into #sla_issue_step from #sla_issue
join dbo.changegroup on dbo.changegroup.issueid=#sla_issue.id
join dbo.changeitem on dbo.changeitem.groupid=dbo.changegroup.id
where FIELD='status' 

delete #sla_issue_step where state not in('1','5');

--Закрытые до @ddateb
delete from #sla_issue
where (select max(ddate) from #sla_issue_step where #sla_issue.id=#sla_issue_step.id and #sla_issue_step.state='5')<@ddateb

delete from #sla_issue_step where #sla_issue_step.id not in(select id from #sla_issue);
--
--Впервые открытые после @ddatee

delete from #sla_issue
where (select min(ddate) from #sla_issue_step where #sla_issue.id=#sla_issue_step.id and #sla_issue_step.state='1')>=@ddatee

delete from #sla_issue_step where #sla_issue_step.id not in(select id from #sla_issue);

--
select         *,(select count(*) from #sla_issue_step slave where slave.ddate<=main.ddate and slave.id=main.id) as numb
into #sla_issue_step_numb
from #sla_issue_step main
--Дублирующиеся step`ы
delete main from #sla_issue_step_numb as main
where exists(select * from #sla_issue_step_numb slave where slave.id=main.id and main.numb-1=slave.numb and slave.state=main.state)
--

--step`ы вне диапазона
delete from #sla_issue_step_numb where ddate not between @ddateb and @ddatee
--

-- добавляем недостающие step`ы
insert into #sla_issue_step_numb
select isnull(id,0),@ddatee,5,999 from #sla_issue_step_numb main where 
numb =(select max(numb) from #sla_issue_step_numb slave where main.id=slave.id group by id) and state=1

insert into #sla_issue_step_numb values(
        isnull((select id from #sla_issue_step_numb main where numb=1 and state=5),0),
        @ddateb,
        1,
        0)

select  main.id,
        main.issuetype,
        main.PROJECT,
        isnull((select sum(DATEDIFF(n, CAST('00:00' AS DATETIME), ddate)) from #sla_issue_step_numb slave where main.id=slave.id and state=5),DATEDIFF(n, CAST('00:00' AS DATETIME), @ddatee)) -
        isnull((select sum(DATEDIFF(n, CAST('00:00' AS DATETIME), ddate)) from #sla_issue_step_numb slave where main.id=slave.id and state=1),DATEDIFF(n, CAST('00:00' AS DATETIME), @ddateb)) as [InWork(minutes)],
        main.otv,
        main.created,
        (select factor from dbo.sla_factor where dbo.sla_factor.component_id=main.component
                and dbo.sla_factor.priority_id=main.priority) as [Factor],
	component
into #rep
from #sla_issue main order by otv,id

select         *, 
        isnull((select numbervalue from dbo.customfieldvalue where issue=#rep.id and customfield=11020),[Factor]*[InWork(minutes)])as ti,
        [Factor]*[InWork(minutes)] as k
         into #rep1 from #rep;

declare @Q float, @a float, @b float;
set @a=isnull((select factor from dbo.sla_factor where dbo.sla_factor.component_id=(select id from dbo.component where cname=@dcomponent) and dbo.sla_factor.priority_id=996),0);
set @b=isnull((select factor from dbo.sla_factor where dbo.sla_factor.component_id=(select id from dbo.component where cname=@dcomponent) and dbo.sla_factor.priority_id=995),0);

set @Q=(select sum(ti) from #rep1);
set @Q=1-(@Q/43200);

declare @sla_owner_count int;
set @sla_owner_count=isnull((select count(*) from sla_owner where sla_type=@sla_type and sla_owner.component_info=@dcomponent),1);

if @sla_owner_count=0 set @sla_owner_count=1;

select distinct @ddateb as ddate,
		sla_owner.owner_info as person,
		-1 as issuetype,
		-1 as project,
		(@a+@b)/@sla_owner_count as bonus,
		-1 as issueid,
		@component as bonustype
	from sla_owner where sla_type=@sla_type and sla_owner.component_info=@dcomponent 
	union all
select 		isnull((select max(#sla_issue_step_numb.ddate) from #sla_issue_step_numb where #sla_issue_step_numb.id=#rep1.id and #sla_issue_step_numb.state=5),-1) as ddate,
		sla_owner.owner_info as person,
		issuetype as issuetype,
		PROJECT as project,
		-(@a+@b-((1-ti/43200)*@a+@b))/@sla_owner_count as bonus,
		id as issueid,
		@component as bonustype
	from #rep1
	join sla_owner on sla_type=@sla_type and sla_owner.component_id=component

drop table #rep1;
drop table #rep;
drop table #sla_issue;
drop table #sla_issue_step;
drop table #sla_issue_step_numb;

SET NOCOUNT ON -- turn the annoying messages back on
END
