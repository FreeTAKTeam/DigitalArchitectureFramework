-- Generated 2024-12-03 2:41:16 PM
--  dRole (GroupName) connected with  dBusinessService (series)
SELECT dRole.Name as dRole,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRole ON connector.End_Object_ID =  dRole.Object_ID
WHERE dRole.Stereotype='dRole'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='Consumes Service'