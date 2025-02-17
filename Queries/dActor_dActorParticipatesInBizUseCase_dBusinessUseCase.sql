-- Generated 2025-01-15 3:33:12 PM
--  dActor (GroupName) connected with  dBusinessUseCase (series)
SELECT dActor.Name as dActor,  dBusinessUseCase.Name as  dBusinessUseCase
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON dBusinessUseCase.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dActor ON connector.End_Object_ID =  dActor.Object_ID
WHERE dActor.Stereotype='dActor'
AND  dBusinessUseCase.Stereotype='dBusinessUseCase'
AND connector.Stereotype='dActorParticipatesInBizUseCase'