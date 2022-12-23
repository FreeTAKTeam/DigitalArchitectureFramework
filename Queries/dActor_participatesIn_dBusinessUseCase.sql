-- Generated 2022-12-20 12:17:43 PM
--  dActor (GroupName) connected with  dBusinessUseCase (series)
SELECT dActor.Name as dActor,  dBusinessUseCase.Name as  dBusinessUseCase
FROM t_object AS dActor
INNER JOIN t_connector as connector ON dActor.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessUseCase ON connector.End_Object_ID =  dBusinessUseCase.Object_ID
WHERE dActor.Stereotype='dBusinessUseCase'
AND  dBusinessUseCase.Stereotype='dActor'
AND connector.Stereotype='participatesIn'