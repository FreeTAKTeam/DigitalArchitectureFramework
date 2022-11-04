-- Generated 10/24/2022 2:16:09 PM
--  dRole (GroupName) connected with  dBusinessService (series)
SELECT dRole.Name as dRole,  dBusinessService.Name as  dBusinessService
FROM t_object AS dRole
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dRole.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dRole'
AND connector.Stereotype='Consumes Service'