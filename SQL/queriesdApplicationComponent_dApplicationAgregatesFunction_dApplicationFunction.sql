-- Generated 10/24/2022 2:11:48 PM
--  dApplicationComponent (GroupName) connected with  dApplicationFunction (series)
SELECT ApplicationComponent.Name as ApplicationComponent,  ApplicationFunction.Name as  ApplicationFunction, ApplicationFunction.Note as description
FROM t_object AS ApplicationComponent
INNER JOIN t_connector as connector ON ApplicationComponent.Object_ID = connector.End_Object_ID
INNER JOIN t_object AS ApplicationFunction ON connector.Start_Object_ID =  ApplicationFunction.Object_ID
WHERE ApplicationComponent.Stereotype='dApplicationComponent'
AND  ApplicationFunction.Stereotype='dApplicationFunction'
AND connector.Stereotype='dApplicationAgregatesFunction'