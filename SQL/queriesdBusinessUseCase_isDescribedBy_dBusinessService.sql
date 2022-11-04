-- Generated 10/24/2022 2:12:14 PM
--  dBusinessUseCase (GroupName) connected with  dBusinessService (series)
SELECT dBusinessUseCase.Name as dBusinessUseCase,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dBusinessUseCase.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dBusinessUseCase'
AND connector.Stereotype='isDescribedBy'