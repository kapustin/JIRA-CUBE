IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactBonusDEV]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactBonusDEV]
GO
CREATE PROCEDURE [dbo].[PopulateFactBonusDEV]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

-------------------------------------
--
--     Сделка отдела разработки
--
-------------------------------------
execute dbo.ask_jira_closed_fix;

-------------------------------------
--
--     Консультация
--
-------------------------------------
insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	 ISNULL(MAX(dimDate.DateKey),-1) date_uid
	,ISNULL(dimPerson.uid,-1) person_uid
	,ISNULL(dimIssueType.uid,-1) issuetype_uid
	,20 bonustype_uid
	,50 bonus
	,ji.ID issueid
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10030 
	and ji.issuetype=60 
	and ji.resolution=1 
	and ji.issuestatus=6
	and newvalue='6'
group by ji.id,dimIssueType.uid,dimPerson.uid;

SET NOCOUNT ON -- turn the annoying messages back on
END
