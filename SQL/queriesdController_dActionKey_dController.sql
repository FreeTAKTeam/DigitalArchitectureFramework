-- Generated 10/24/2022 2:12:56 PM
--  dController (GroupName) connected with  dController (series)
SELECT dController.Name as dController,  dController.Name as  dController
FROM t_object AS dController
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dController.Object_ID
WHERE dController.Stereotype='dController'
AND  dController.Stereotype='dController'
AND connector.Stereotype='dActionKey'