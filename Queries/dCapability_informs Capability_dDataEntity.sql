-- Generated 2022-12-20 12:19:28 PM
--  dCapability (GroupName) connected with  dDataEntity (series)
SELECT dCapability.Name as dCapability,  dDataEntity.Name as  dDataEntity
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON dCapability.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDataEntity ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dCapability.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dCapability'
AND connector.Stereotype='informs Capability'