-- Generated 2024-09-06 11:29:13 AM
--  dBusinessService (GroupName) connected with  dBusinessService (series)
SELECT dBusinessService.Name as dBusinessService,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessService ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dBusinessService.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='dRelatedService'