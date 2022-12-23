-- Generated 2022-12-20 12:24:41 PM
--  dValueStream (GroupName) connected with  dBusinessProcess (series)
SELECT dValueStream.Name as dValueStream,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dValueStream
INNER JOIN t_connector as connector ON dValueStream.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessProcess ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dValueStream.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dValueStream'
AND connector.Stereotype='Includes Processes'