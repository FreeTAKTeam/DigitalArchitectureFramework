-- Generated 10/24/2022 2:15:22 PM
--  dPhysicalService (GroupName) connected with  dBusinessService (series)
SELECT dPhysicalService.Name as dPhysicalService,  dBusinessService.Name as  dBusinessService
FROM t_object AS dPhysicalService
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dPhysicalService.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dPhysicalService'
AND connector.Stereotype='Implements'