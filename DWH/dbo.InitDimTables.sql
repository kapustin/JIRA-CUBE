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
     VALUES (1,'ИТ-поддержка сделка','Обращения пользователей в ИТ-подержку');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (2,'КЦ - Сделка (Инцидент)','Обращения клиентов на terminal@oceanbanc.ru');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (3,'КЦ - Сделка (Qiwi-claim) закрытие','Оплата закрытия претензий ОСМП');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (4,'КЦ - Сделка (Платеж)','Оплата закрытых заявок типа Платежи');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (5,'КЦ - Сделка (Субдилер)','Оплата закрытых субдилеров');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (6,'КЦ - Сделка (Овердрафт)','Оплата закрытых заявок типа Овердрафт');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (7,'КЦ - Сделка (Консультация)','Оплата закрытых заявок типа Консультация');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (8,'КЦ - Сделка (Терминалы)','Оплата закрытых заявок типа Терминалы');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (9,'КЦ - Сделка (Qiwi-claim) переходы','Оплата переходов по претезиям ОСМП');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (10,'Проекты','Суммы по закрытым проектам');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (11,'КЦ - Сделка (Выгрузка для ОДБК)','Оплата выгрузки данных для запросов ОДБК');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (12,'Дежурство 5005 (Дни)','Бонус за ношение дежурного телефона');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (13,'Дежурство 5005 (Обращения)','Бонус за работу дежурного');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (14,'Дежурство ИС (Дни)','Бонус за ношение дежурного телефона');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (15,'Дежурство ИС (Ворклоги)','Бонус за работу дежурного');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (16,'Дежурство Поддержки банка','Бонус за работу дежурного');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (17,'Разработка подзадач','Бонус за разработку в проекте DEV');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (18,'Разработка архитектуры','Бонус за архитектуру в проекте DEV');     
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (19,'ИС - Сделка','Бонус за запросы в проекте INFR');
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (20,'ИС - СЛА','СЛА по сервисам, поддерживаемым ИС'); 
INSERT INTO dbo.dimBonusType (uid,name,description)
     VALUES (21,'Оклад','Оклад сотрудников, распределенный по запросам'); 
     
SET NOCOUNT ON -- turn the annoying messages back on
END
GO
