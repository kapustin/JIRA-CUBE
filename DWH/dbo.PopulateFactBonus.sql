IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactBonus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactBonus]
GO
CREATE PROCEDURE [dbo].[PopulateFactBonus]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
	ISNULL(MAX(dimDate.DateKey),-1),
	ISNULL(dimPerson.uid,-1),
	ISNULL(dimIssueType.uid,-1),
	1,
	case when count(distinct il.source)-count(distinct ji_dev.id)=0 and count(distinct il.source)>0 then 10/2 
		when COUNT(distinct il.source)>0 then 10*(4+COUNT(distinct il_dev.destination))/2 
		else 10 end bonus,
	ji.ID
from jiraissue ji
	join changegroup cg on cg.issueid=ji.id
	join changeitem ci on ci.groupid=cg.id and field='status'
	left outer join issuelink il on il.destination=ji.id and il.linktype=10010 --il.source - dev
	left outer join jiraissue ji_dev on ji_dev.id=il.source and ji_dev.resolution = 2
	left outer join issuelink il_dev on il_dev.source=il.source and il_dev.linktype=10000
	left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
	left outer join dimPerson on dimPerson.ADname=ji.assignee
	left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10180 
	and ji.issuetype=33 
	and ji.resolution=1 
	and ji.issuestatus=6
	and cg.CREATED>'2012-03-01'
	and CONVERT(varchar(5),newvalue)='6' and CONVERT(varchar(5),oldvalue)='5'
group by ji.id,dimIssueType.uid,dimPerson.uid;

-- удалить обращения с установленым CF "Повторное обращение" в "Да"
delete from dbo.factBonus
where exists(select * from dbo.customfieldvalue cfv 
where factBonus.issueid=cfv.ISSUE and cfv.CUSTOMFIELD=10660 and cfv.STRINGVALUE='Да');


SET NOCOUNT ON -- turn the annoying messages back on
END

GO

