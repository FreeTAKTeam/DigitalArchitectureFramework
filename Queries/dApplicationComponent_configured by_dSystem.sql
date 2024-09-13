-- Generated 2024-09-10 10:54:27 AM
--  dApplicationComponent (GroupName) connected with  dSystem (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dSystem.Name as  dSystem
FROM t_object AS dSystem
INNER JOIN t_connector as connector ON dSystem.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationComponent'
AND  dSystem.Stereotype='dSystem'
AND connector.Stereotype='configured by'