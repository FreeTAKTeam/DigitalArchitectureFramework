-- Generated 2022-12-20 12:18:49 PM
--  dBusinessUseCase (GroupName) connected with  dBusinessService (series)
SELECT dBusinessUseCase.Name as dBusinessUseCase,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON dBusinessUseCase.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessService ON connector.End_Object_ID =  dBusinessService.Object_ID
WHERE dBusinessUseCase.Stereotype='dBusinessService'
AND  dBusinessService.Stereotype='dBusinessUseCase'
AND connector.Stereotype='isDescribedBy'