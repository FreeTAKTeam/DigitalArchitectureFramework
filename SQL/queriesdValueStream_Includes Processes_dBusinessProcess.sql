-- Generated 10/24/2022 2:16:43 PM
--  dValueStream (GroupName) connected with  dBusinessProcess (series)
SELECT dValueStream.Name as dValueStream,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dValueStream
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dValueStream.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dValueStream'
AND connector.Stereotype='Includes Processes'