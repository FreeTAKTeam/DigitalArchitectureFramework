-- Generated 2024-12-10 1:08:51 PM
--  dModelClass (GroupName) connected with  dDataEntity (series)
SELECT dModelClass.Name as dModelClass,  dDataEntity.Name as  dDataEntity
FROM t_object AS dDataEntity
INNER JOIN t_connector as connector ON dDataEntity.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dModelClass ON connector.End_Object_ID =  dModelClass.Object_ID
WHERE dModelClass.Stereotype='dModelClass'
AND  dDataEntity.Stereotype='dDataEntity'
AND connector.Stereotype='RealizesEntity'