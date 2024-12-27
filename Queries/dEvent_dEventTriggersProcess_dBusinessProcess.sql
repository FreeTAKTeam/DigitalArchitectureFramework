-- Generated 2024-12-10 1:02:26 PM
--  dEvent (GroupName) connected with  dBusinessProcess (series)
SELECT dEvent.Name as dEvent,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dBusinessProcess
INNER JOIN t_connector as connector ON dBusinessProcess.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dEvent ON connector.End_Object_ID =  dEvent.Object_ID
WHERE dEvent.Stereotype='dEvent'
AND  dBusinessProcess.Stereotype='dBusinessProcess'
AND connector.Stereotype='dEventTriggersProcess'