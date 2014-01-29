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

DECLARE @bonus_start date = '2012-06-01';

insert into dbo.factBonus (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
select
        ISNULL(MAX(dimDate.DateKey),-1),
        ISNULL(dimPerson.uid,-1),
        ISNULL(dimIssueType.uid,-1),
        0,
        CASE 
                WHEN (DATEDIFF(dd, MAX(ji.DUEDATE), MAX(cg.CREATED)) <= 0) THEN 50 ELSE -500
        END bonus,
        ji.ID
from jiraissue ji
        join changegroup cg on cg.issueid=ji.id
        join changeitem ci on ci.groupid=cg.id and field='status'
        left outer join dimDate on dimDate.FullDate=DATEADD(dd, 0, DATEDIFF(dd, 0, cg.created))
        left outer join dimPerson on dimPerson.ADname=ji.assignee
        left outer join dimIssueType on dimIssueType.issuetype_id=ji.issuetype and dimIssueType.project_id=ji.PROJECT
where ji.project=10070 
        and ji.issuetype in (32,38) 
        and ji.resolution=1 
        and cg.CREATED>=@bonus_start
        and newvalue='5'
group by ji.id,dimIssueType.uid,dimPerson.uid;

SET NOCOUNT ON -- turn the annoying messages back on
END
