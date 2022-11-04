-- Generated 10/24/2022 2:16:29 PM
--  dTable (GroupName) connected with  dDataEntity (series)
SELECT dTable.Name as dTable,  dDataEntity.Name as  dDataEntity
FROM t_object AS dTable
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dTable.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dTable'
AND connector.Stereotype='isFunctionallyImplementedBy'