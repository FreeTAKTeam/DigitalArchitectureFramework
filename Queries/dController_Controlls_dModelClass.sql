-- Generated 2024-09-10 10:58:06 AM
--  dController (GroupName) connected with  dModelClass (series)
SELECT dController.Name as dController,  dModelClass.Name as  dModelClass
FROM t_object AS dModelClass
INNER JOIN t_connector as connector ON dModelClass.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dController ON connector.End_Object_ID =  dController.Object_ID
WHERE dController.Stereotype='dController'
AND  dModelClass.Stereotype='dModelClass'
AND connector.Stereotype='Controlls'