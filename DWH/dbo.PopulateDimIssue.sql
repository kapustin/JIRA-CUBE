IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateDimIssue]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateDimIssue]
GO
CREATE PROCEDURE [dbo].[PopulateDimIssue]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

insert into dbo.dimIssue (uid,pkey,info,client_uid,service_uid,priority_uid,issuetype_uid)
select	 ji.ID
		,ji.pkey
		,ji.SUMMARY info
		,ISNULL(dimPerson.uid,-1) client_uid
		,ISNULL(dimService.uid,(SELECT uid FROM dimService WHERE name='�� ����������')) service_uid
		,ISNULL(dimPriority.uid,-1) priority_uid
		,ISNULL(dimIssueType.uid,-1) issuetype_uid
FROM jiraissue ji
		left outer join dimIssueType on dimIssueType.project_id=ji.PROJECT and dimIssueType.issuetype_id=ji.issuetype
		left outer join customfieldvalue client on ji.ID=client.ISSUE and client.CUSTOMFIELD=10146
		left outer join customfieldvalue serv on ji.ID=serv.ISSUE and serv.CUSTOMFIELD in (select id from customfield where cfname='������')
		left outer join dimPerson on dimPerson.ADName=client.STRINGVALUE
		left outer join dimService on dimService.name=serv.STRINGVALUE and dimService.issuetype_uid=dimIssueType.uid
		left outer join dimPriority on dimPriority.uid=ji.PRIORITY
group by ji.ID,ji.pkey,ji.SUMMARY,dimPerson.uid,dimService.uid,dimPriority.uid,dimIssueType.uid

SET NOCOUNT ON -- turn the annoying messages back on
END

GO

