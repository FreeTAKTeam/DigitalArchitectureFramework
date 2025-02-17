-- Generated 2025-01-15 3:34:37 PM
--  dController (GroupName) connected with  dBusinessUseCase (series)
SELECT dController.Name as dController,  dBusinessUseCase.Name as  dBusinessUseCase
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON dBusinessUseCase.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dController ON connector.End_Object_ID =  dController.Object_ID
WHERE dController.Stereotype='dController'
AND  dBusinessUseCase.Stereotype='dBusinessUseCase'
AND connector.Stereotype='dUseCaseisImplementedByController'