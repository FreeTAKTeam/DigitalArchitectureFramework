-- Generated 10/24/2022 2:11:41 PM
--  dApplicationComponent (GroupName) connected with  dLogicalAppComponent (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dLogicalAppComponent.Name as  dLogicalAppComponent
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dLogicalAppComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dLogicalAppComponent'
AND  dLogicalAppComponent.Stereotype='dApplicationComponent'
AND connector.Stereotype='Realizes'