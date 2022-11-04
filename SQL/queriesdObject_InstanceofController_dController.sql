-- Generated 10/24/2022 2:14:46 PM
--  dObject (GroupName) connected with  dController (series)
SELECT dObject.Name as dObject,  dController.Name as  dController
FROM t_object AS dObject
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dController.Object_ID
WHERE dObject.Stereotype='dController'
AND  dController.Stereotype='dObject'
AND connector.Stereotype='InstanceofController'