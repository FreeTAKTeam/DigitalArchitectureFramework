-- Generated 2024-09-16 1:50:47 PM
--  dActor (GroupName) connected with  dRole (series)
SELECT dActor.Name as dActor,  dRole.Name as  dRole
FROM t_object AS dRole
INNER JOIN t_connector as connector ON dRole.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dActor ON connector.End_Object_ID =  dActor.Object_ID
WHERE dActor.Stereotype='dActor'
AND  dRole.Stereotype='dRole'
AND connector.Stereotype='isPerformedBy'