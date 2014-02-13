IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateDimBonusType]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateDimBonusType]
GO
CREATE PROCEDURE [dbo].[PopulateDimBonusType]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

-- Заполнение типов бонусов по СЛА плюс для ИС
INSERT INTO dimBonusType (name,description,department)
SELECT component_info,
		'Бонус за СЛА(+) по компоненте ' + component_info,
		'Инфраструктура'
FROM sla_owner 
WHERE sla_type = 1


SET NOCOUNT ON -- turn the annoying messages back on
END

GO
