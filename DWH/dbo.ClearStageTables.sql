IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClearStageTables]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ClearStageTables]
GO
CREATE PROCEDURE [dbo].[ClearStageTables]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

TRUNCATE TABLE dbo.jiraissue;
TRUNCATE TABLE dbo.changegroup;
TRUNCATE TABLE dbo.changeitem;
TRUNCATE TABLE dbo.issuelink;
TRUNCATE TABLE dbo.customfieldvalue;
TRUNCATE TABLE dbo.customfield;

SET NOCOUNT ON -- turn the annoying messages back on
END
GO

