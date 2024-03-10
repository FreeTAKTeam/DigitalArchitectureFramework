-- Generated 2024-02-28 10:54:09 AM
--  dAPI (GroupName) connected with  dPhysicalService (series)
SELECT dAPI.Name as dAPI,  dPhysicalService.Name as  dPhysicalService
FROM t_object AS dPhysicalService
INNER JOIN t_connector as connector ON dPhysicalService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dAPI ON connector.End_Object_ID =  dAPI.Object_ID
WHERE dAPI.Stereotype='dAPI'
AND  dPhysicalService.Stereotype='dPhysicalService'
AND connector.Stereotype=''