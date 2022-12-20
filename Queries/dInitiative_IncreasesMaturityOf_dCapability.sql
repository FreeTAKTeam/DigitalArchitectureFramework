-- Generated 2022-12-20 12:20:51 PM
--  dInitiative (GroupName) connected with  dCapability (series)
SELECT dInitiative.Name as dInitiative,  dCapability.Name as  dCapability
FROM t_object AS dInitiative
INNER JOIN t_connector as connector ON dInitiative.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCapability ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dInitiative.Stereotype='dCapability'
AND  dCapability.Stereotype='dInitiative'
AND connector.Stereotype='IncreasesMaturityOf'