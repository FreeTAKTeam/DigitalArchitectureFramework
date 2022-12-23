-- Generated 2022-12-20 12:19:48 PM
--  dController (GroupName) connected with  dBusinessUseCase (series)
SELECT dController.Name as dController,  dBusinessUseCase.Name as  dBusinessUseCase
FROM t_object AS dController
INNER JOIN t_connector as connector ON dController.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessUseCase ON connector.End_Object_ID =  dBusinessUseCase.Object_ID
WHERE dController.Stereotype='dBusinessUseCase'
AND  dBusinessUseCase.Stereotype='dController'
AND connector.Stereotype='isImplementedBy'