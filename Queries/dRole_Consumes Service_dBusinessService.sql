-- Generated 2022-12-20 12:24:03 PM
--  dRole (GroupName) connected with  dBusinessService (series)
SELECT dRole.Name as dRole,  dBusinessService.Name as  dBusinessService
FROM t_object AS dRole
INNER JOIN t_connector as connector ON dRole.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessService ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dRole.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dRole'
AND connector.Stereotype='Consumes Service'