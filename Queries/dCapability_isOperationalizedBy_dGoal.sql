-- Generated 2022-12-20 12:19:18 PM
--  dCapability (GroupName) connected with  dGoal (series)
SELECT dCapability.Name as dCapability,  dGoal.Name as  dGoal
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON dCapability.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dGoal ON connector.End_Object_ID =  dGoal.Object_ID
WHERE dCapability.Stereotype='dGoal'
AND  dGoal.Stereotype='dCapability'
AND connector.Stereotype='isOperationalizedBy'