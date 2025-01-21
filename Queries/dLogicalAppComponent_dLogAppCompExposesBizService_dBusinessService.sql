-- Generated 2025-01-15 3:36:47 PM
--  dLogicalAppComponent (GroupName) connected with  dBusinessService (series)
SELECT dLogicalAppComponent.Name as dLogicalAppComponent,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dLogicalAppComponent ON connector.End_Object_ID =  dLogicalAppComponent.Object_ID
WHERE dLogicalAppComponent.Stereotype='dLogicalAppComponent'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='dLogAppCompExposesBizService'