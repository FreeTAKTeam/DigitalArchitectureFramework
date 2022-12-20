-- Generated 2022-12-20 12:23:23 PM
--  dRequirement (GroupName) connected with  dGoal (series)
SELECT dRequirement.Name as dRequirement,  dGoal.Name as  dGoal
FROM t_object AS dRequirement
INNER JOIN t_connector as connector ON dRequirement.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dGoal ON connector.End_Object_ID =  dGoal.Object_ID
WHERE dRequirement.Stereotype='dGoal'
AND  dGoal.Stereotype='dRequirement'
AND connector.Stereotype='is related to'