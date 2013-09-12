IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClearDimTables]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ClearDimTables]
GO
CREATE PROCEDURE [dbo].[ClearDimTables]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

DELETE FROM dbo.dimIssue;
DELETE FROM dbo.dimPriority;
DELETE FROM dbo.dimIssueType;
DELETE FROM dbo.dimIssueStatus;
DELETE FROM dbo.dimPerson;
DELETE FROM dbo.dimService;
DELETE FROM dimBonusType;


SET NOCOUNT ON -- turn the annoying messages back on
END
GO

