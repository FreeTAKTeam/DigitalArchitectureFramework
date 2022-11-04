-- Generated 10/24/2022 2:12:49 PM
--  dController (GroupName) connected with  dModelClass (series)
SELECT dController.Name as dController,  dModelClass.Name as  dModelClass
FROM t_object AS dController
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dModelClass.Object_ID
WHERE dController.Stereotype='dModelClass'
AND  dModelClass.Stereotype='dController'
AND connector.Stereotype='Controlls'