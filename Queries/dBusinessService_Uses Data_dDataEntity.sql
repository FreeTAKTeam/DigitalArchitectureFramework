-- Generated 2022-12-20 12:18:38 PM
--  dBusinessService (GroupName) connected with  dDataEntity (series)
SELECT dBusinessService.Name as dBusinessService,  dDataEntity.Name as  dDataEntity
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDataEntity ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dBusinessService.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dBusinessService'
AND connector.Stereotype='Uses Data'