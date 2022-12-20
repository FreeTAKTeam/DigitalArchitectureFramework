-- Generated 2022-12-20 12:22:54 PM
--  dPhysicalService (GroupName) connected with  dBusinessService (series)
SELECT dPhysicalService.Name as dPhysicalService,  dBusinessService.Name as  dBusinessService
FROM t_object AS dPhysicalService
INNER JOIN t_connector as connector ON dPhysicalService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessService ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dPhysicalService.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dPhysicalService'
AND connector.Stereotype='Implements'