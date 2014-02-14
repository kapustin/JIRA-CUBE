IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[calculate_sla_plus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[calculate_sla_plus]
GO
CREATE PROCEDURE [dbo].[calculate_sla_plus](@month datetime,@component varchar(150))
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

declare @ddateb datetime, @ddatee datetime, @dcomponent nvarchar(150), @sla_type int;
set dateformat dmy;
set @ddateb=DATEADD(month, DATEDIFF(month, 0, @month), 0)--'01.10.2013';
set @ddatee=DATEADD(month, DATEDIFF(month, 0, @month)+1, 0);--'01.11.2013';
set @dcomponent=@component;--'Рабочие станции';
set @sla_type=1;

select 
	dbo.jiraissue.id,
	dbo.jiraissue.priority,
	(select STRINGVALUE from dbo.customfieldvalue where customfield=10510 and issue=dbo.jiraissue.id) as Otv,
	dbo.jiraissue.created,
	dbo.component.id as component,
	dbo.jiraissue.issuetype,
	dbo.jiraissue.PROJECT
	
into #sla_issue 
from dbo.jiraissue
join dbo.nodeassociation on dbo.nodeassociation.SOURCE_NODE_ID=dbo.jiraissue.id
join dbo.component on dbo.component.id=dbo.nodeassociation.SINK_NODE_ID
where 
dbo.jiraissue.issuetype in (32,38)and
dbo.component.cname=@dcomponent and dbo.nodeassociation.ASSOCIATION_TYPE='IssueComponent'and 
dbo.jiraissue.resolution<>2 

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
--Впервые закрытые изменения после @ddatee

delete from #sla_issue
where (select min(ddate) from #sla_issue_step where #sla_issue.id=#sla_issue_step.id and #sla_issue_step.state='5' and #sla_issue.issuetype=38)>=@ddatee
delete from #sla_issue_step where #sla_issue_step.id not in(select id from #sla_issue);

--
select 	*,(select count(*) from #sla_issue_step slave where slave.ddate<=main.ddate and slave.id=main.id) as numb
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
select id,@ddatee,5,999 	
from #sla_issue_step_numb main where
numb=(select max(numb) from #sla_issue_step_numb slave where main.id=slave.id group by id) and state=1

insert into #sla_issue_step_numb
select id,@ddateb,1,0
from #sla_issue_step_numb main where
numb=1 and state=5

select 	main.id,
	isnull((select sum(DATEDIFF(n, CAST('00:00' AS DATETIME), ddate)) from #sla_issue_step_numb slave where main.id=slave.id and state=5),DATEDIFF(n, CAST('00:00' AS DATETIME), @ddatee)) -
	isnull((select sum(DATEDIFF(n, CAST('00:00' AS DATETIME), ddate)) from #sla_issue_step_numb slave where main.id=slave.id and state=1),DATEDIFF(n, CAST('00:00' AS DATETIME), @ddateb)) as [InWork(minutes)],
	main.otv,
	main.created,
	case main.issuetype
	 when 32 then	
		(select factor from dbo.sla_factor where dbo.sla_factor.component_id=main.component and dbo.sla_factor.priority_id=main.priority)
	 when 38 then '0'
	end  as [Factor],
	main.project, 
	main.issuetype,
	case main.issuetype
	 when 32 then	--стоимость инцидент
		isnull((select factor from dbo.sla_factor where dbo.sla_factor.component_id=main.component and dbo.sla_factor.priority_id=999),0)
	 when 38 then	--стоимость изменение
		isnull((select factor from dbo.sla_factor where dbo.sla_factor.component_id=main.component and dbo.sla_factor.priority_id=998),0)
	end as IssueMaxPrice
	into #rep
from #sla_issue main order by otv,id;

select 	*, 
	isnull((select numbervalue from dbo.customfieldvalue where issue=#rep.id and customfield=11020),[Factor]*[InWork(minutes)])as ti
 	into #rep1 from #rep;


declare @Q float, @Qpl float;
set @Qpl=isnull((select factor from dbo.sla_factor where dbo.sla_factor.component_id=(select id from dbo.component where cname=@dcomponent) and dbo.sla_factor.priority_id=997),0);
set @Q=(select sum(ti) from #rep1);
set @Q=1-(@Q/43200);
set @Q=(@Q-@Qpl)/(1-@Qpl);


delete from #rep1 where IssueMaxPrice=0;
select 	*,
	[Factor]*[InWork(minutes)] as k,
	case issuetype 
		when 38 then IssueMaxPrice 
		when 32 then  @Q*IssueMaxPrice
	end as Price
into #rep2
from #rep1;


select 		isnull((select max(#sla_issue_step_numb.ddate) from #sla_issue_step_numb where #sla_issue_step_numb.id=#rep2.id and #sla_issue_step_numb.state=5),-1) as ddate,
		otv as person,
		issuetype,
		project,
		Price as bonus,
		id as issueid,
		@component as bonustype
	from #rep2

drop table #rep2;
drop table #rep1;
drop table #rep;
drop table #sla_issue;
drop table #sla_issue_step;
drop table #sla_issue_step_numb; 

SET NOCOUNT ON -- turn the annoying messages back on
END
