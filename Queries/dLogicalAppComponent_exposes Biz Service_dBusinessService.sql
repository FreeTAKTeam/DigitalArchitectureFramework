-- Generated 2022-12-20 12:21:23 PM
--  dLogicalAppComponent (GroupName) connected with  dBusinessService (series)
SELECT dLogicalAppComponent.Name as dLogicalAppComponent,  dBusinessService.Name as  dBusinessService
FROM t_object AS dLogicalAppComponent
INNER JOIN t_connector as connector ON dLogicalAppComponent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessService ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dLogicalAppComponent.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dLogicalAppComponent'
AND connector.Stereotype='exposes Biz Service'