-- Generated 10/24/2022 2:11:42 PM
--  dApplicationComponent (GroupName) connected with  dSystem (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dSystem.Name as  dSystem
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dSystem.Object_ID
WHERE dApplicationComponent.Stereotype='dSystem'
AND  dSystem.Stereotype='dApplicationComponent'
AND connector.Stereotype='configured by'