-- Generated 2022-12-20 12:23:35 PM
--  dResource (GroupName) connected with  dCapability (series)
SELECT dResource.Name as dResource,  dCapability.Name as  dCapability
FROM t_object AS dResource
INNER JOIN t_connector as connector ON dResource.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCapability ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dResource.Stereotype='dCapability'
AND  dCapability.Stereotype='dResource'
AND connector.Stereotype='supports'