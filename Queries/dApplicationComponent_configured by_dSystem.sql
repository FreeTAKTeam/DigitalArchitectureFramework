-- Generated 2022-12-20 12:18:03 PM
--  dApplicationComponent (GroupName) connected with  dSystem (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dSystem.Name as  dSystem
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON dApplicationComponent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dSystem ON connector.End_Object_ID =  dSystem.Object_ID
WHERE dApplicationComponent.Stereotype='dSystem'
AND  dSystem.Stereotype='dApplicationComponent'
AND connector.Stereotype='configured by'