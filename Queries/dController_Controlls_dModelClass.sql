-- Generated 2022-12-20 12:19:44 PM
--  dController (GroupName) connected with  dModelClass (series)
SELECT dController.Name as dController,  dModelClass.Name as  dModelClass
FROM t_object AS dController
INNER JOIN t_connector as connector ON dController.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dModelClass ON connector.End_Object_ID =  dModelClass.Object_ID
WHERE dController.Stereotype='dModelClass'
AND  dModelClass.Stereotype='dController'
AND connector.Stereotype='Controlls'