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
    
-- Наполнение измерения 'Тип бонуса'
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (1,'Сделка ИТ-поддержки','Обращения пользователей в ИТ-подержку');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (2,'Сделка КЦ (Инцидент)','Обращения клиентов на terminal@oceanbanc.ru');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (3,'Сделка КЦ (Qiwi-claim) закрытие','Оплата закрытия претензий ОСМП');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (4,'Сделка КЦ (Платеж)','Оплата закрытых заявок типа Платежи');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (5,'Сделка КЦ (Субдилер)','Оплата закрытых субдилеров');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (6,'Сделка КЦ (Овердрафт)','Оплата закрытых заявок типа Овердрафт');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (7,'Сделка КЦ (Консультация)','Оплата закрытых заявок типа Консультация');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (8,'Сделка КЦ (Терминалы)','Оплата закрытых заявок типа Терминалы');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (9,'Сделка КЦ (Qiwi-claim) переходы','Оплата переходов по претезиям ОСМП');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (10,'Проекты','Суммы по закрытым проектам');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (11,'Сделка КЦ (Выгрузка для ОДБК)','Оплата выгрузки данных для запросов ОДБК');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (12,'Дежурный 5005 (Дни)','Бонус за ношение дежурного телефона');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (13,'Дежурный 5005 (Обращения)','Бонус за работу дежурного');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (14,'Дежурство ИС (Дни)','Бонус за ношение дежурного телефона');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (15,'Дежурство ИС (Ворклоги)','Бонус за работу дежурного');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (16,'Дежурство Поддержки банка','Бонус за работу дежурного');
     
SET NOCOUNT ON -- turn the annoying messages back on
END
GO
