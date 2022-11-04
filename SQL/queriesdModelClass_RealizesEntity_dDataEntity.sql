-- Generated 10/24/2022 2:14:31 PM
--  dModelClass (GroupName) connected with  dDataEntity (series)
SELECT dModelClass.Name as dModelClass,  dDataEntity.Name as  dDataEntity
FROM t_object AS dModelClass
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dModelClass.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dModelClass'
AND connector.Stereotype='RealizesEntity'