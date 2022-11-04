-- Generated 10/24/2022 2:15:46 PM
--  dRequirement (GroupName) connected with  dGoal (series)
SELECT dRequirement.Name as dRequirement,  dGoal.Name as  dGoal
FROM t_object AS dRequirement
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dGoal.Object_ID
WHERE dRequirement.Stereotype='dGoal'
AND  dGoal.Stereotype='dRequirement'
AND connector.Stereotype='is related to'