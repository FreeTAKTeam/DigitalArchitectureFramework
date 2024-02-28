-- Generated 2024-02-28 10:44:13 AM
--  dBusinessProcess (GroupName) connected with  dBusinessProcess (series)
SELECT dBusinessProcess.Name as dBusinessProcess,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dBusinessProcess
INNER JOIN t_connector as connector ON dBusinessProcess.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessProcess ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dBusinessProcess.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dBusinessProcess'
AND connector.Stereotype='Flows to'