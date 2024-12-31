-- Generated 2024-12-30 3:49:27 PM
--  dDataEntity (GroupName) connected with  dDataEntity (series)
SELECT dDataEntity.Name as dDataEntity,  dDataEntity.Name as  dDataEntity
FROM t_object AS dDataEntity
INNER JOIN t_connector as connector ON dDataEntity.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDataEntity ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dDataEntity.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dDataEntity'
AND connector.Stereotype='AssociatedEntity'