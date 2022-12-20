-- Generated 2022-12-20 12:17:35 PM
--  dActivity (GroupName) connected with  dAction (series)
SELECT dActivity.Name as dActivity,  dAction.Name as  dAction
FROM t_object AS dActivity
INNER JOIN t_connector as connector ON dActivity.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dAction ON connector.End_Object_ID =  dAction.Object_ID
WHERE dActivity.Stereotype='dAction'
AND  dAction.Stereotype='dActivity'
AND connector.Stereotype='contains Action'