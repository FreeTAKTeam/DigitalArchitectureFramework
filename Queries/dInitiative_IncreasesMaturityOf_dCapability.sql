-- Generated 2024-02-28 10:47:16 AM
--  dInitiative (GroupName) connected with  dCapability (series)
SELECT dInitiative.Name as dInitiative,  dCapability.Name as  dCapability
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON dCapability.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dInitiative ON connector.End_Object_ID =  dInitiative.Object_ID
WHERE dInitiative.Stereotype='dInitiative'
AND  dCapability.Stereotype='dCapability'
AND connector.Stereotype='IncreasesMaturityOf'