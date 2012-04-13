IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateDimIssue]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateDimIssue]
GO
CREATE PROCEDURE [dbo].[PopulateDimIssue]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

insert into dbo.dimIssue (uid,pkey,info,client_uid)
select	 ji.ID
		,ji.pkey
		,ji.SUMMARY info
		,ISNULL(dimPerson.uid,-1) client_uid
FROM jiraissue ji
		left outer join customfieldvalue val on ji.ID=val.ISSUE and val.CUSTOMFIELD=10146
		left outer join dimPerson on dimPerson.ADName=val.STRINGVALUE
group by ji.ID,ji.pkey,ji.SUMMARY,dimPerson.uid

SET NOCOUNT ON -- turn the annoying messages back on
END

GO

