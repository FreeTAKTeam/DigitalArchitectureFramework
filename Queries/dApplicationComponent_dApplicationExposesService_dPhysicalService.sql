-- Generated 2024-12-03 2:03:22 PM
--  dApplicationComponent (GroupName) connected with  dPhysicalService (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dPhysicalService.Name as  dPhysicalService
FROM t_object AS dPhysicalService
INNER JOIN t_connector as connector ON dPhysicalService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationComponent'
AND  dPhysicalService.Stereotype='dPhysicalService'
AND connector.Stereotype='dApplicationExposesService'