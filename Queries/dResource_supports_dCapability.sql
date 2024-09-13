-- Generated 2024-09-10 11:10:04 AM
--  dResource (GroupName) connected with  dCapability (series)
SELECT dResource.Name as dResource,  dCapability.Name as  dCapability
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON dCapability.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dResource ON connector.End_Object_ID =  dResource.Object_ID
WHERE dResource.Stereotype='dResource'
AND  dCapability.Stereotype='dCapability'
AND connector.Stereotype='supports'