-- Generated 2022-12-20 12:21:47 PM
--  dModelClass (GroupName) connected with  dDataEntity (series)
SELECT dModelClass.Name as dModelClass,  dDataEntity.Name as  dDataEntity
FROM t_object AS dModelClass
INNER JOIN t_connector as connector ON dModelClass.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDataEntity ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dModelClass.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dModelClass'
AND connector.Stereotype='RealizesEntity'