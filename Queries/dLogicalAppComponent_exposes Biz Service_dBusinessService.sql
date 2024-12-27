-- Generated 2024-12-10 1:07:52 PM
--  dLogicalAppComponent (GroupName) connected with  dBusinessService (series)
SELECT dLogicalAppComponent.Name as dLogicalAppComponent,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dLogicalAppComponent ON connector.End_Object_ID =  dLogicalAppComponent.Object_ID
WHERE dLogicalAppComponent.Stereotype='dLogicalAppComponent'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='exposes Biz Service'