-- Generated 10/24/2022 2:13:00 PM
--  dDataEntity (GroupName) connected with  dDataEntity (series)
SELECT dDataEntity.Name as dDataEntity,  dDataEntity.Name as  dDataEntity
FROM t_object AS dDataEntity
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dDataEntity.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dDataEntity'
AND connector.Stereotype='AssociatedEntity'