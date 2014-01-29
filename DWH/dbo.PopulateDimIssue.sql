IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateDimIssue]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateDimIssue]
GO
CREATE PROCEDURE [dbo].[PopulateDimIssue]
AS
BEGIN
SET NOCOUNT OFF -- turn off all the 1 row inserted messages

insert into dbo.dimIssue (uid,pkey,info,client_uid,service_uid,priority_uid,issuetype_uid)
select	 ji.ID
		,ji.pkey
		,ji.SUMMARY info
		,ISNULL(dimPerson.uid,-1) client_uid
		,ISNULL(MAX(dimService.uid),(SELECT uid FROM dimService WHERE name='Не определено')) service_uid -- Нужно исправить
		,ISNULL(dimPriority.uid,-1) priority_uid
		,ISNULL(dimIssueType.uid,-1) issuetype_uid
FROM jiraissue ji
		left outer join dimIssueType on dimIssueType.project_id=ji.PROJECT and dimIssueType.issuetype_id=ji.issuetype
		left outer join customfieldvalue client on ji.ID=client.ISSUE and client.CUSTOMFIELD=10146
		left outer join customfieldvalue serv on ji.ID=serv.ISSUE and serv.CUSTOMFIELD in (select id from customfield where cfname='Сервис')
		left outer join dimPerson on dimPerson.ADName=client.STRINGVALUE
		left outer join dimService on dimService.name=serv.STRINGVALUE and dimService.issuetype_uid=dimIssueType.uid
		left outer join dimPriority on dimPriority.uid=ji.PRIORITY
group by ji.ID,ji.pkey,ji.SUMMARY,dimPerson.uid,dimPriority.uid,dimIssueType.uid

-- Заказчиком запроса в проекте ODBK является автор запроса
UPDATE dbo.dimIssue SET client_uid=ISNULL(dimPerson.uid,-1)  
FROM jiraissue ji
LEFT OUTER JOIN dimPerson ON dimPerson.ADName=ji.REPORTER
WHERE ji.ID=dimIssue.uid
	AND ji.PROJECT=10350	-- ODBK
	
-- Заказчиком запроса в проектах КЦ является соответствующий человек
UPDATE dbo.dimIssue SET client_uid=10160 -- соответсвующий человек
FROM jiraissue ji
LEFT OUTER JOIN dimPerson ON dimPerson.ADName=ji.REPORTER
WHERE ji.ID=dimIssue.uid
	AND ji.PROJECT in (10280,10311)
	and dimIssue.client_uid=-1
	
-- Заказчиком в проекте INFR является заказчик из связанного SUP
UPDATE dbo.dimIssue SET client_uid=ISNULL(dimPerson.uid,10030)  -- соответсвующий человек (IT)
FROM jiraissue ji
LEFT OUTER JOIN issuelink jl ON jl.SOURCE=ji.ID
LEFT OUTER JOIN jiraissue ji_sup ON ji_sup.ID=jl.DESTINATION AND ji_sup.PROJECT=10180 --SUP
LEFT OUTER JOIN customfieldvalue client ON ji_sup.ID=client.ISSUE AND client.CUSTOMFIELD=10146 -- Заказчик
LEFT OUTER JOIN dimPerson ON dimPerson.ADName=client.STRINGVALUE
WHERE ji.ID=dimIssue.uid
        AND ji.PROJECT=10070        -- INFR

-- Сервис запросов разработки - комбинация компонентов
UPDATE dbo.dimIssue SET service_uid=ISNULL(dimService.uid,-1)  
FROM jiraissue
LEFT OUTER JOIN dimService ON dimService.name=rtrim((select c.cname + ' ' 
							from nodeassociation node
								join component c on c.id = node.SINK_NODE_ID
								and node.SINK_NODE_ENTITY = 'Component'
							where node.SOURCE_NODE_ENTITY = 'Issue'
								and node.SOURCE_NODE_ID = jiraissue.ID
							order by c.cname
							FOR XML PATH ('')
							)) and dimService.context='Разработка ПО'
WHERE jiraissue.ID=dimIssue.uid
        AND jiraissue.PROJECT=10030        -- DEV

SET NOCOUNT ON -- turn the annoying messages back on
END

GO

