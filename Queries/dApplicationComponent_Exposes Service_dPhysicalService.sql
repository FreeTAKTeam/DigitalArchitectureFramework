-- Generated 2022-12-20 12:18:08 PM
--  dApplicationComponent (GroupName) connected with  dPhysicalService (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dPhysicalService.Name as  dPhysicalService
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON dApplicationComponent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dPhysicalService ON connector.End_Object_ID =  dPhysicalService.Object_ID
WHERE dApplicationComponent.Stereotype='dPhysicalService'
AND  dPhysicalService.Stereotype='dApplicationComponent'
AND connector.Stereotype='Exposes Service'