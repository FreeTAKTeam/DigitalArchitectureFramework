-- Generated 10/24/2022 2:11:46 PM
--  dApplicationComponent (GroupName) connected with  dApplicationComponent (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationComponent'
AND  dApplicationComponent.Stereotype='dApplicationComponent'
AND connector.Stereotype='Connected with Application'