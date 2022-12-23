-- Generated 2022-12-20 12:20:19 PM
--  dEvent (GroupName) connected with  dBusinessProcess (series)
SELECT dEvent.Name as dEvent,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dEvent
INNER JOIN t_connector as connector ON dEvent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessProcess ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dEvent.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dEvent'
AND connector.Stereotype=''