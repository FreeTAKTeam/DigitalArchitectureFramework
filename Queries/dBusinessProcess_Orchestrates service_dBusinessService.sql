-- Generated 2024-12-05 10:26:04 AM
--  dBusinessProcess (GroupName) connected with  dBusinessService (series)
SELECT dBusinessProcess.Name as dBusinessProcess,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessProcess ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dBusinessProcess.Stereotype='dBusinessProcess'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='Orchestrates service'