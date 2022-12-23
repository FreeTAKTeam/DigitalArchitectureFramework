-- Generated 2022-12-20 12:20:34 PM
--  dGoal (GroupName) connected with  dObjective (series)
SELECT dGoal.Name as dGoal,  dObjective.Name as  dObjective
FROM t_object AS dGoal
INNER JOIN t_connector as connector ON dGoal.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dObjective ON connector.End_Object_ID =  dObjective.Object_ID
WHERE dGoal.Stereotype='dObjective'
AND  dObjective.Stereotype='dGoal'
AND connector.Stereotype='has Milestone'