-- Generated 2024-12-10 12:55:41 PM
--  dApplicationComponent (GroupName) connected with  dApplicationFunction (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dApplicationFunction.Name as  dApplicationFunction
FROM t_object AS dApplicationFunction
INNER JOIN t_connector as connector ON dApplicationFunction.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationComponent'
AND  dApplicationFunction.Stereotype='dApplicationFunction'
AND connector.Stereotype='dApplicationAgregatesFunction'