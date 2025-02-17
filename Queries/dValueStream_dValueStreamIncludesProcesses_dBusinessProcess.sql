-- Generated 2025-01-15 3:41:27 PM
--  dValueStream (GroupName) connected with  dBusinessProcess (series)
SELECT dValueStream.Name as dValueStream,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dBusinessProcess
INNER JOIN t_connector as connector ON dBusinessProcess.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dValueStream ON connector.End_Object_ID =  dValueStream.Object_ID
WHERE dValueStream.Stereotype='dValueStream'
AND  dBusinessProcess.Stereotype='dBusinessProcess'
AND connector.Stereotype='dValueStreamIncludesProcesses'