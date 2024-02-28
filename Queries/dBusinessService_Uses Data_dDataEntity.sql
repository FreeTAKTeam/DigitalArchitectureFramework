-- Generated 2024-02-28 10:44:23 AM
--  dBusinessService (GroupName) connected with  dDataEntity (series)
SELECT dBusinessService.Name as dBusinessService,  dDataEntity.Name as  dDataEntity
FROM t_object AS dDataEntity
INNER JOIN t_connector as connector ON dDataEntity.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessService ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dBusinessService.Stereotype='dBusinessService'
AND  dDataEntity.Stereotype='dDataEntity'
AND connector.Stereotype='Uses Data'