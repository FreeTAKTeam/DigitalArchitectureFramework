-- Generated 2024-12-31 1:00:12 PM
--  dBusinessUseCase (GroupName) connected with  dBusinessService (series)
SELECT dBusinessUseCase.Name as dBusinessUseCase,  dBusinessService.Name as  dBusinessService
FROM t_object AS dBusinessService
INNER JOIN t_connector as connector ON dBusinessService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessUseCase ON connector.End_Object_ID =  dBusinessUseCase.Object_ID
WHERE dBusinessUseCase.Stereotype='dBusinessUseCase'
AND  dBusinessService.Stereotype='dBusinessService'
AND connector.Stereotype='dBizServIsDescribedByUseCase'