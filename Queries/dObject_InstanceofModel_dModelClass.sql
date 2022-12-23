-- Generated 2022-12-20 12:22:08 PM
--  dObject (GroupName) connected with  dModelClass (series)
SELECT dObject.Name as dObject,  dModelClass.Name as  dModelClass
FROM t_object AS dObject
INNER JOIN t_connector as connector ON dObject.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dModelClass ON connector.End_Object_ID =  dModelClass.Object_ID
WHERE dObject.Stereotype='dModelClass'
AND  dModelClass.Stereotype='dObject'
AND connector.Stereotype='InstanceofModel'