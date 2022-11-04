-- Generated 10/24/2022 2:11:56 PM
--  dBusinessProcess (GroupName) connected with  dBusinessService (series)
SELECT dBusinessProcess.Name as dBusinessProcess,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessProcess
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dBusinessProcess.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dBusinessProcess'
AND connector.Stereotype='Orchestrates service'