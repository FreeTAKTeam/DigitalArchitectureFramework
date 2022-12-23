-- Generated 2022-12-20 12:17:53 PM
--  dActor (GroupName) connected with  dRole (series)
SELECT dActor.Name as dActor,  dRole.Name as  dRole
FROM t_object AS dActor
INNER JOIN t_connector as connector ON dActor.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRole ON connector.End_Object_ID =  dRole.Object_ID
WHERE dActor.Stereotype='dRole'
AND  dRole.Stereotype='dActor'
AND connector.Stereotype='isPerformedBy'