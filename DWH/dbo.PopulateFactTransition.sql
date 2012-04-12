IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactTransition]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactTransition]
GO
CREATE PROCEDURE [dbo].[PopulateFactTransition]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages
BEGIN TRANSACTION trn;
insert into dbo.factTransition (date_uid,person_uid,client_uid,service_uid,priority_uid, issuetype_uid,oldstatus_uid,newstatus_uid,issueid,changegroupid)
select 
	ISNULL(dimDate.DateKey,-1) date_uid,
	ISNULL(dimPerson.uid,-1) person_uid,
	-1 client_uid,
	(select uid from dimService where name='Не определено') service_uid,
	ISNULL(dimPriority.uid,-1) priority_uid,
	ISNULL(dimIssueType.uid,-1) issuetype_uid,
	ISNULL(oldis.uid,-1) oldstatus_uid,
	ISNULL(newis.uid,-1) newstatus_uid,
	ji.ID issueid,
	cg.id changegroupid
from jiraissue ji 
	join changegroup cg on ji.ID=cg.issueid
	join changeitem ci on cg.ID=ci.groupid
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADName=cg.AUTHOR
	left outer join dimIssueStatus oldis on convert(varchar(10),ci.oldvalue)=convert(varchar(10),oldis.uid)
	left outer join dimIssueStatus newis on convert(varchar(10),ci.newvalue)=convert(varchar(10),newis.uid)
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
	left outer join dimPriority on dimPriority.uid=ji.PRIORITY
where ci.FIELD='status'
group by dimDate.DateKey,dimPerson.uid,	dimIssueType.uid,	dimPriority.uid, oldis.uid,	newis.uid,	ji.ID ,	cg.id;

-- Создания запросов, как переходы
insert into dbo.factTransition (date_uid,person_uid,client_uid,service_uid,priority_uid, issuetype_uid,oldstatus_uid,newstatus_uid,issueid,changegroupid)
select 
	ISNULL(dimDate.DateKey,-1) date_uid,
	ISNULL(dimPerson.uid,-1) person_uid,
	-1 client_uid,
	(select uid from dimService where name='Не определено') service_uid,
	ISNULL(dimPriority.uid,-1) priority_uid,
	ISNULL(dimIssueType.uid,-1) issuetype_uid,
	0 oldstatus_uid,
	ISNULL(newis.uid,-1) newstatus_uid,
	ji.ID issueid,
	null changegroupid
from jiraissue ji 
	join changegroup cg on cg.issueid=ji.ID
	join changeitem ci on ci.groupid=cg.ID
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, ji.created))
	left outer join dimPerson on dimPerson.ADName=ji.REPORTER
	left outer join dimIssueStatus newis on convert(varchar(10),ci.oldvalue)=convert(varchar(10),newis.uid)
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
	left outer join dimPriority on dimPriority.uid=ji.PRIORITY
where cg.ID=(select min(changegroupid) chi from factTransition
					where issueid=ji.ID) 
	and ci.FIELD='status'
group by dimDate.DateKey, dimPerson.uid,dimPriority.uid,	dimIssueType.uid,	newis.uid,	ji.ID;

-- Заполнение заказчика
update factTransition 
	set client_uid=pers.uid
from dbo.customfieldvalue cfv  
	join dimPerson pers on pers.ADName=cfv.STRINGVALUE 
where cfv.ISSUE=factTransition.issueid 
		and cfv.CUSTOMFIELD=10146;

-- Заполнение сервиса
update factTransition 
	set service_uid=srv.uid
from dbo.customfieldvalue cfv WITH (INDEX(stringval__issue_cf))
	join dimService srv on srv.name=cfv.STRINGVALUE 
where cfv.CUSTOMFIELD in (select id from customfield where cfname='Сервис') 
	and cfv.ISSUE=factTransition.issueid 
	and srv.issuetype_uid=factTransition.issuetype_uid;

COMMIT TRANSACTION trn;

SET NOCOUNT ON -- turn the annoying messages back on
END

GO

