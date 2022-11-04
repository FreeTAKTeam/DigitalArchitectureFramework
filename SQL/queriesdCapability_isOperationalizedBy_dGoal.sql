-- Generated 10/24/2022 2:12:31 PM
--  dCapability (GroupName) connected with  dGoal (series)
SELECT dCapability.Name as dCapability,  dGoal.Name as  dGoal
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dGoal.Object_ID
WHERE dCapability.Stereotype='dGoal'
AND  dGoal.Stereotype='dCapability'
AND connector.Stereotype='isOperationalizedBy'