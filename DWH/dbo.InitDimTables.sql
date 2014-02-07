IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InitDimTables]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InitDimTables]
GO
CREATE PROCEDURE [dbo].[InitDimTables]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

INSERT INTO dbo.dimPriority (uid,name,description)
    VALUES (-1,'Не определено','Не определено');
INSERT INTO  dbo.dimIssueStatus (uid,name,description) 
    VALUES (0,'_Новый','Создание нового запроса');
INSERT INTO  dbo.dimIssueStatus (uid,name,description) 
    VALUES (-1,'Не определено','Не определено');	
INSERT INTO dbo.dimPerson (uid,ADName,ShortName,TabNum,FullName,Position,Department,Division)
    VALUES (-1,'Не определено','Не определено',-1,'Не определено','Не определено','Не определено','Не определено');
    
SET IDENTITY_INSERT dimService ON;
INSERT INTO dbo.dimService (uid,context,name)
    VALUES (-1,'Не определено','Не определено');
SET IDENTITY_INSERT dimService OFF;

SET IDENTITY_INSERT dimIssueType ON;
INSERT INTO  dbo.dimIssueType (uid, issuetype_id, issuetype_name, issuetype_desc,project_id,project_key,project_name,project_desc) 
    VALUES (-1,-1,'Не определено','Не определено',-1,'Не определено','Не определено','Не определено');
SET IDENTITY_INSERT dimIssueType OFF;

INSERT INTO  dbo.dimIssue (uid, pkey, info, client_uid, service_uid, priority_uid,issuetype_uid) 
VALUES (-1,'N/A','Не определено',-1,-1,-1,-1);
     
SET NOCOUNT ON -- turn the annoying messages back on
END
GO
