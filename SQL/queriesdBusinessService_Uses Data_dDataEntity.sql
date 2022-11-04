-- Generated 10/24/2022 2:12:06 PM
--  dBusinessService (GroupName) connected with  dDataEntity (series)
SELECT dBusinessService.Name as dBusinessService,  dDataEntity.Name as  dDataEntity
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dDataEntity.Object_ID
WHERE dBusinessService.Stereotype='dDataEntity'
AND  dDataEntity.Stereotype='dBusinessService'
AND connector.Stereotype='Uses Data'