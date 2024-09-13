-- Generated 2024-09-10 10:54:34 AM
--  dApplicationComponent (GroupName) connected with  dPhysicalService (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dPhysicalService.Name as  dPhysicalService
FROM t_object AS dPhysicalService
INNER JOIN t_connector as connector ON dPhysicalService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationComponent'
AND  dPhysicalService.Stereotype='dPhysicalService'
AND connector.Stereotype='Exposes Service'