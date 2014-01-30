IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateFactBonusSalary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateFactBonusSalary]
GO
CREATE PROCEDURE [dbo].[PopulateFactBonusSalary]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

-------------------------------------
--
--     Оклады в ИТ-поддержке
--
--     Внимание! Выполнять только после рассчта бонуса @sup_bonustype!
--
-------------------------------------
declare @sup_bonustype int = 1; -- Слелка ИТ-поддержки

insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select	factBonus.date_uid
		,dimPerson.uid
		,factBonus.issuetype_uid
		,21 bonustype_uid
		,factBonus.bonus / b.bonus * emp_rel.month_salary
		,issueid
from factBonus
join dimDate on dimDate.DateKey = factBonus.date_uid
join dimPerson on dimPerson.Department = 'Отдел ИТ-поддержки'
join 
	(select dimDate.CalendarYearMonth CalendarYearMonth, sum(bonus) bonus from factBonus
	join dimDate on dimDate.DateKey = factBonus.date_uid
	where factBonus.bonustype_uid = @sup_bonustype
	group by dimDate.CalendarYearMonth) b on b.CalendarYearMonth = dimDate.CalendarYearMonth
join emp_rel on emp_rel.tabnum = dimPerson.TabNum and dimDate.FullDate between emp_rel.ddateb and ISNULL(emp_rel.ddatee,getdate())
where factBonus.bonustype_uid = @sup_bonustype;

SET NOCOUNT ON -- turn the annoying messages back on
END

