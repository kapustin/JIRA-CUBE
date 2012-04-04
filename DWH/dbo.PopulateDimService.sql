IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateDimService]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateDimService]
GO
CREATE PROCEDURE [dbo].[PopulateDimService]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

	insert into dbo.dimService (context,issuetype_uid,name)
	select it.project_name+' - '+it.issuetype_name
		,it.uid
		,val.STRINGVALUE 
	from customfieldvalue val
		join jiraissue ji on val.ISSUE=ji.ID
		join dimIssueType it on it.issuetype_id=ji.issuetype and it.project_id=ji.PROJECT
	where val.CUSTOMFIELD in (select id from customfield where cfname='Сервис')
	group by it.project_name,it.uid,it.issuetype_name,val.STRINGVALUE
	order by 1,3;

SET NOCOUNT ON -- turn the annoying messages back on
END

GO

