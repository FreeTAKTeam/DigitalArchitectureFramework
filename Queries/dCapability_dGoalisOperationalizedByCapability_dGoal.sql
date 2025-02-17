-- Generated 2025-01-15 3:34:11 PM
--  dCapability (GroupName) connected with  dGoal (series)
SELECT dCapability.Name as dCapability,  dGoal.Name as  dGoal
FROM t_object AS dGoal
INNER JOIN t_connector as connector ON dGoal.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCapability ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dCapability.Stereotype='dCapability'
AND  dGoal.Stereotype='dGoal'
AND connector.Stereotype='dGoalisOperationalizedByCapability'