-- Generated 2024-09-10 10:58:15 AM
--  dController (GroupName) connected with  dBusinessUseCase (series)
SELECT dController.Name as dController,  dBusinessUseCase.Name as  dBusinessUseCase
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON dBusinessUseCase.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dController ON connector.End_Object_ID =  dController.Object_ID
WHERE dController.Stereotype='dController'
AND  dBusinessUseCase.Stereotype='dBusinessUseCase'
AND connector.Stereotype='isImplementedBy'