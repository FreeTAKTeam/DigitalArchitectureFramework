-- Generated 2024-07-30 3:27:47 PM
--  dRequirement (GroupName) connected with  dGoal (series)
SELECT dRequirement.Name as dRequirement,  dGoal.Name as  dGoal
FROM t_object AS dGoal
INNER JOIN t_connector as connector ON dGoal.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRequirement ON connector.End_Object_ID =  dRequirement.Object_ID
WHERE dRequirement.Stereotype='dRequirement'
AND  dGoal.Stereotype='dGoal'
AND connector.Stereotype='is related to'