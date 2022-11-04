-- Generated 10/24/2022 2:12:44 PM
--  dController (GroupName) connected with  dPhysicalService (series)
SELECT dController.Name as dController,  dPhysicalService.Name as  dPhysicalService
FROM t_object AS dController
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dPhysicalService.Object_ID
WHERE dController.Stereotype='dPhysicalService'
AND  dPhysicalService.Stereotype='dController'
AND connector.Stereotype='Implements Service'