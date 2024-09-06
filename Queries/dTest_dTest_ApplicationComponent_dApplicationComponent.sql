-- Generated 2024-09-06 11:38:11 AM
--  dTest (GroupName) connected with  dApplicationComponent (series)
SELECT dTest.Name as dTest,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON dApplicationComponent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dTest ON connector.End_Object_ID =  dTest.Object_ID
WHERE dTest.Stereotype='dTest'
AND  dApplicationComponent.Stereotype='dApplicationComponent'
AND connector.Stereotype='dTest_ApplicationComponent'