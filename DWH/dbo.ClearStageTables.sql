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
TRUNCATE TABLE dbo.emp_quality_coefficient;
TRUNCATE TABLE dbo.entrance;
TRUNCATE TABLE dbo.emp_schedule;
TRUNCATE TABLE dbo.ddate;
TRUNCATE TABLE dbo.emp_dutyroster;
TRUNCATE TABLE dbo.emp_dutytype;
TRUNCATE TABLE dbo.jiraworklog;
TRUNCATE TABLE dbo.customfieldoption;
TRUNCATE TABLE dbo.component;
TRUNCATE TABLE dbo.nodeassociation;
TRUNCATE TABLE dbo.OS_CURRENTSTEP;
TRUNCATE TABLE dbo.jiraaction;
TRUNCATE TABLE dbo.base_artefact;
TRUNCATE TABLE dbo.reg_rule;
TRUNCATE TABLE dbo.reg_link_project_rule;
TRUNCATE TABLE dbo.reg_link_issuestatus_rule;
TRUNCATE TABLE dbo.reg_link_issuetype_rule;
TRUNCATE TABLE dbo.reg_summ;
TRUNCATE TABLE dbo.reg_violation;
TRUNCATE TABLE dbo.reg_violation_user;
TRUNCATE TABLE dbo.emp_rel;

SET NOCOUNT ON -- turn the annoying messages back on
END
GO

