-- Generated 10/24/2022 2:12:45 PM
--  dController (GroupName) connected with  dView (series)
SELECT dController.Name as dController,  dView.Name as  dView
FROM t_object AS dController
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dView.Object_ID
WHERE dController.Stereotype='dView'
AND  dView.Stereotype='dController'
AND connector.Stereotype='Governs'