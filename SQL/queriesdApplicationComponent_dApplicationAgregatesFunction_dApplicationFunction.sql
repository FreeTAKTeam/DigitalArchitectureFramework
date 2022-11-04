-- Generated 10/24/2022 2:11:48 PM
--  dApplicationComponent (GroupName) connected with  dApplicationFunction (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dApplicationFunction.Name as  dApplicationFunction
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dApplicationFunction.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationFunction'
AND  dApplicationFunction.Stereotype='dApplicationComponent'
AND connector.Stereotype='dApplicationAgregatesFunction'