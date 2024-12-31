-- Generated 2024-12-31 1:01:44 PM
--  dGoal (GroupName) connected with  dObjective (series)
SELECT dGoal.Name as dGoal,  dObjective.Name as  dObjective
FROM t_object AS dObjective
INNER JOIN t_connector as connector ON dObjective.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dGoal ON connector.End_Object_ID =  dGoal.Object_ID
WHERE dGoal.Stereotype='dGoal'
AND  dObjective.Stereotype='dObjective'
AND connector.Stereotype='dGoalhasObjective'