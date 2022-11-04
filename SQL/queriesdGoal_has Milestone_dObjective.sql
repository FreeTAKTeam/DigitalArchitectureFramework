-- Generated 10/24/2022 2:13:33 PM
--  dGoal (GroupName) connected with  dObjective (series)
SELECT dGoal.Name as dGoal,  dObjective.Name as  dObjective
FROM t_object AS dGoal
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dObjective.Object_ID
WHERE dGoal.Stereotype='dObjective'
AND  dObjective.Stereotype='dGoal'
AND connector.Stereotype='has Milestone'