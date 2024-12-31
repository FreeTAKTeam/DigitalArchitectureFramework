-- Generated 2024-12-31 1:00:45 PM
--  dController (GroupName) connected with  dApplicationFunction (series)
SELECT dController.Name as dController,  dApplicationFunction.Name as  dApplicationFunction
FROM t_object AS dApplicationFunction
INNER JOIN t_connector as connector ON dApplicationFunction.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dController ON connector.End_Object_ID =  dController.Object_ID
WHERE dController.Stereotype='dController'
AND  dApplicationFunction.Stereotype='dApplicationFunction'
AND connector.Stereotype='dControllerImplementsFunction'