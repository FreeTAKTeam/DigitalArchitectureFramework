-- Generated 10/24/2022 2:14:44 PM
--  dObject (GroupName) connected with  dModelClass (series)
SELECT dObject.Name as dObject,  dModelClass.Name as  dModelClass
FROM t_object AS dObject
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dModelClass.Object_ID
WHERE dObject.Stereotype='dModelClass'
AND  dModelClass.Stereotype='dObject'
AND connector.Stereotype='InstanceofModel'