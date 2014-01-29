IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactBonusINFR]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactBonusINFR]
GO
CREATE PROCEDURE [dbo].[PopulateFactBonusINFR]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

-------------------------------------
--
--     Сделка ИС
--
-------------------------------------



SET NOCOUNT ON -- turn the annoying messages back on
END
