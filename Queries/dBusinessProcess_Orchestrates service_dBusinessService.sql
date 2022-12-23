-- Generated 2022-12-20 12:18:25 PM
--  dBusinessProcess (GroupName) connected with  dBusinessService (series)
SELECT dBusinessProcess.Name as dBusinessProcess,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessProcess
INNER JOIN t_connector as connector ON dBusinessProcess.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessService ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dBusinessProcess.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dBusinessProcess'
AND connector.Stereotype='Orchestrates service'