-- Generated 10/24/2022 2:15:54 PM
--  dResource (GroupName) connected with  dCapability (series)
SELECT dResource.Name as dResource,  dCapability.Name as  dCapability
FROM t_object AS dResource
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dResource.Stereotype='dCapability'
AND  dCapability.Stereotype='dResource'
AND connector.Stereotype='supports'