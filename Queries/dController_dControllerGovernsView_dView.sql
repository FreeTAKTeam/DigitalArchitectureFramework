-- Generated 2025-01-15 3:34:31 PM
--  dController (GroupName) connected with  dView (series)
SELECT dController.Name as dController,  dView.Name as  dView
FROM t_object AS dView
INNER JOIN t_connector as connector ON dView.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dController ON connector.End_Object_ID =  dController.Object_ID
WHERE dController.Stereotype='dController'
AND  dView.Stereotype='dView'
AND connector.Stereotype='dControllerGovernsView'