-- Generated 2024-09-06 11:29:25 AM
--  dBusinessUseCase (GroupName) connected with  dActivity (series)
SELECT dBusinessUseCase.Name as dBusinessUseCase,  dActivity.Name as  dActivity
FROM t_object AS dActivity
INNER JOIN t_connector as connector ON dActivity.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessUseCase ON connector.End_Object_ID =  dBusinessUseCase.Object_ID
WHERE dBusinessUseCase.Stereotype='dBusinessUseCase'
AND  dActivity.Stereotype='dActivity'
AND connector.Stereotype='Contains Activities'