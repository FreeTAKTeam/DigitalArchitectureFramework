-- Generated 2025-01-15 3:35:11 PM
--  dGoal (GroupName) connected with  dGoal (series)
SELECT dGoal.Name as dGoal,  dGoal.Name as  dGoal
FROM t_object AS dGoal
INNER JOIN t_connector as connector ON dGoal.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dGoal ON connector.End_Object_ID =  dGoal.Object_ID
WHERE dGoal.Stereotype='dGoal'
AND  dGoal.Stereotype='dGoal'
AND connector.Stereotype='dGoalAggregatesGoal'