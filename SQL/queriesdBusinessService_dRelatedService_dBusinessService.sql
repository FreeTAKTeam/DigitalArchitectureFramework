-- Generated 10/24/2022 2:12:08 PM
--  dBusinessService (GroupName) connected with  dBusinessService (series)
SELECT dBusinessService.Name as dBusinessService,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dBusinessService.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='dRelatedService'