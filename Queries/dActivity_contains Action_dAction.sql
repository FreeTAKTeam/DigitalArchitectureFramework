-- Generated 2024-12-30 10:10:13 AM
--  dActivity (GroupName) connected with  dAction (series)
SELECT dActivity.Name as dActivity,  dAction.Name as  dAction
FROM t_object AS dAction
INNER JOIN t_connector as connector ON dAction.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dActivity ON connector.End_Object_ID =  dActivity.Object_ID
WHERE dActivity.Stereotype='dActivity'
AND  dAction.Stereotype='dAction'
AND connector.Stereotype='contains Action'