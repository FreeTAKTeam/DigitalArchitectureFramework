-- Generated 2025-01-15 3:38:28 PM
--  dPhysicalService (GroupName) connected with  dBusinessService (series)
SELECT dPhysicalService.Name as dPhysicalService,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dPhysicalService ON connector.End_Object_ID =  dPhysicalService.Object_ID
WHERE dPhysicalService.Stereotype='dPhysicalService'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='dPhysicalServiceImplementsBusinessService'