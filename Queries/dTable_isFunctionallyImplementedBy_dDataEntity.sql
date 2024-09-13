-- Generated 2024-09-10 11:13:02 AM
--  dTable (GroupName) connected with  dDataEntity (series)
SELECT dTable.Name as dTable,  dDataEntity.Name as  dDataEntity
FROM t_object AS dDataEntity
INNER JOIN t_connector as connector ON dDataEntity.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dTable ON connector.End_Object_ID =  dTable.Object_ID
WHERE dTable.Stereotype='dTable'
AND  dDataEntity.Stereotype='dDataEntity'
AND connector.Stereotype='isFunctionallyImplementedBy'