-- Generated 10/24/2022 2:14:07 PM
--  dLogicalAppComponent (GroupName) connected with  dBusinessService (series)
SELECT dLogicalAppComponent.Name as dLogicalAppComponent,  dBusinessService.Name as  dBusinessService
FROM t_object AS dLogicalAppComponent
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dLogicalAppComponent.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dLogicalAppComponent'
AND connector.Stereotype='exposes Biz Service'