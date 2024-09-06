-- Generated 2024-09-06 11:35:53 AM
--  dPhysicalService (GroupName) connected with  dBusinessService (series)
SELECT dPhysicalService.Name as dPhysicalService,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dPhysicalService ON connector.End_Object_ID =  dPhysicalService.Object_ID
WHERE dPhysicalService.Stereotype='dPhysicalService'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='Implements'