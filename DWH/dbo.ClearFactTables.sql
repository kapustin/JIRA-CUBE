IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClearFactTables]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[ClearFactTables]
GO
CREATE PROCEDURE [dbo].[ClearFactTables]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

TRUNCATE TABLE dbo.factTransition;
TRUNCATE TABLE dbo.factBonus;

SET NOCOUNT ON -- turn the annoying messages back on
END
GO

