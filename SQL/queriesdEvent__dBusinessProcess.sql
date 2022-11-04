-- Generated 10/24/2022 2:13:22 PM
--  dEvent (GroupName) connected with  dBusinessProcess (series)
SELECT dEvent.Name as dEvent,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dEvent
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dEvent.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dEvent'
AND connector.Stereotype=''