-- Generated 10/24/2022 2:12:37 PM
--  dCapability (GroupName) connected with  dDataEntity (series)
SELECT dCapability.Name as dCapability,  dDataEntity.Name as  dDataEntity
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dCapability.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dCapability'
AND connector.Stereotype='informs Capability'