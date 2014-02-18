IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateDimBonusType]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateDimBonusType]
GO
CREATE PROCEDURE [dbo].[PopulateDimBonusType]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

-- Заполнение типов бонусов по СЛА для ИС
SELECT sla_type_info+' '+component_info,
		'Бонус за СЛА по компоненте ' + component_info,
		'Инфраструктура'
FROM sla_owner 
GROUP BY component_info, sla_type_info;

SET NOCOUNT ON -- turn the annoying messages back on
END

GO
