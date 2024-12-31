-- Generated 2024-12-31 12:59:42 PM
--  dApplicationComponent (GroupName) connected with  dLogicalAppComponent (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dLogicalAppComponent.Name as  dLogicalAppComponent
FROM t_object AS dLogicalAppComponent
INNER JOIN t_connector as connector ON dLogicalAppComponent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationComponent'
AND  dLogicalAppComponent.Stereotype='dLogicalAppComponent'
AND connector.Stereotype='dApplicationComponentRealizesogicalComponent'