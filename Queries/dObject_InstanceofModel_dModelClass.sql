-- Generated 2024-12-10 1:10:12 PM
--  dObject (GroupName) connected with  dModelClass (series)
SELECT dObject.Name as dObject,  dModelClass.Name as  dModelClass
FROM t_object AS dModelClass
INNER JOIN t_connector as connector ON dModelClass.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dObject ON connector.End_Object_ID =  dObject.Object_ID
WHERE dObject.Stereotype='dObject'
AND  dModelClass.Stereotype='dModelClass'
AND connector.Stereotype='InstanceofModel'