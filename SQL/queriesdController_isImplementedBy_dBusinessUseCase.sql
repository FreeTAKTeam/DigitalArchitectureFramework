-- Generated 10/24/2022 2:12:51 PM
--  dController (GroupName) connected with  dBusinessUseCase (series)
SELECT dController.Name as dController,  dBusinessUseCase.Name as  dBusinessUseCase
FROM t_object AS dController
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessUseCase.Object_ID
WHERE dController.Stereotype='dBusinessUseCase'
AND  dBusinessUseCase.Stereotype='dController'
AND connector.Stereotype='isImplementedBy'