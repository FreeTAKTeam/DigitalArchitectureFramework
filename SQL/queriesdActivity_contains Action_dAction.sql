-- Generated 10/24/2022 2:11:25 PM
--  dActivity (GroupName) connected with  dAction (series)
SELECT dActivity.Name as dActivity,  dAction.Name as  dAction
FROM t_object AS dActivity
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dAction.Object_ID
WHERE dActivity.Stereotype='dAction'
AND  dAction.Stereotype='dActivity'
AND connector.Stereotype='contains Action'