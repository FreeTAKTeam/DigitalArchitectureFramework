-- Generated 2024-09-16 2:07:50 PM
--  dObject (GroupName) connected with  dView (series)
SELECT dObject.Name as dObject,  dView.Name as  dView
FROM t_object AS dView
INNER JOIN t_connector as connector ON dView.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dObject ON connector.End_Object_ID =  dObject.Object_ID
WHERE dObject.Stereotype='dObject'
AND  dView.Stereotype='dView'
AND connector.Stereotype='InstanceofView'