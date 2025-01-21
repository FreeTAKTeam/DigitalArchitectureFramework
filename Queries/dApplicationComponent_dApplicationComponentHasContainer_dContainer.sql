-- Generated 2025-01-15 3:33:30 PM
--  dApplicationComponent (GroupName) connected with  dContainer (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dContainer.Name as  dContainer
FROM t_object AS dContainer
INNER JOIN t_connector as connector ON dContainer.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationComponent'
AND  dContainer.Stereotype='dContainer'
AND connector.Stereotype='dApplicationComponentHasContainer'