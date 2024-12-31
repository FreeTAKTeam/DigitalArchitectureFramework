-- Generated 2024-12-31 1:00:55 PM
--  dController (GroupName) connected with  dModelClass (series)
SELECT dController.Name as dController,  dModelClass.Name as  dModelClass
FROM t_object AS dModelClass
INNER JOIN t_connector as connector ON dModelClass.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dController ON connector.End_Object_ID =  dController.Object_ID
WHERE dController.Stereotype='dController'
AND  dModelClass.Stereotype='dModelClass'
AND connector.Stereotype='dControllerControllsModel'