-- Generated 10/24/2022 2:14:48 PM
--  dObject (GroupName) connected with  dView (series)
SELECT dObject.Name as dObject,  dView.Name as  dView
FROM t_object AS dObject
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dView.Object_ID
WHERE dObject.Stereotype='dView'
AND  dView.Stereotype='dObject'
AND connector.Stereotype='InstanceofView'