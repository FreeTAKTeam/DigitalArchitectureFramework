-- Generated 10/24/2022 2:13:45 PM
--  dInitiative (GroupName) connected with  dCapability (series)
SELECT dInitiative.Name as dInitiative,  dCapability.Name as  dCapability
FROM t_object AS dInitiative
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dInitiative.Stereotype='dCapability'
AND  dCapability.Stereotype='dInitiative'
AND connector.Stereotype='IncreasesMaturityOf'