-- Generated 2024-02-28 10:45:24 AM
--  dCapability (GroupName) connected with  dDataEntity (series)
SELECT dCapability.Name as dCapability,  dDataEntity.Name as  dDataEntity
FROM t_object AS dDataEntity
INNER JOIN t_connector as connector ON dDataEntity.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCapability ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dCapability.Stereotype='dCapability'
AND  dDataEntity.Stereotype='dDataEntity'
AND connector.Stereotype='informs Capability'