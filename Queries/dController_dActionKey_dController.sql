-- Generated 2024-12-03 2:12:49 PM
--  dController (GroupName) connected with  dController (series)
SELECT dController.Name as dController,  dController.Name as  dController
FROM t_object AS dController
INNER JOIN t_connector as connector ON dController.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dController ON connector.End_Object_ID =  dController.Object_ID
WHERE dController.Stereotype='dController'
AND  dController.Stereotype='dController'
AND connector.Stereotype='dActionKey'