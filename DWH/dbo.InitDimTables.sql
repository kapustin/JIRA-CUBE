IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InitDimTables]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InitDimTables]
GO
CREATE PROCEDURE [dbo].[InitDimTables]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

INSERT INTO dbo.dimPriority (uid,name,description)
    VALUES (-1,'�� ����������','�� ����������');
INSERT INTO  dbo.dimIssueStatus (uid,name,description) 
	VALUES (0,'_�����','�������� ������ �������');	
INSERT INTO dbo.dimPerson (uid,ADName,ShortName,TabNum,FullName,Position,Department,Division)
    VALUES (-1,'�� ����������','�� ����������',-1,'�� ����������','�� ����������','�� ����������','�� ����������');
INSERT INTO dbo.dimService (context,name)
    VALUES ('�� ����������','�� ����������');

SET NOCOUNT ON -- turn the annoying messages back on
END
GO

