-- Generated 2025-01-15 3:37:42 PM
--  dObject (GroupName) connected with  dController (series)
SELECT dObject.Name as dObject,  dController.Name as  dController
FROM t_object AS dController
INNER JOIN t_connector as connector ON dController.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dObject ON connector.End_Object_ID =  dObject.Object_ID
WHERE dObject.Stereotype='dObject'
AND  dController.Stereotype='dController'
AND connector.Stereotype='dObjectInstanceofController'