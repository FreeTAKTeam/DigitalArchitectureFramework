-- Generated 10/24/2022 2:12:15 PM
--  dBusinessUseCase (GroupName) connected with  dActivity (series)
SELECT dBusinessUseCase.Name as dBusinessUseCase,  dActivity.Name as  dActivity
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dActivity.Object_ID
WHERE dBusinessUseCase.Stereotype='dActivity'
AND  dActivity.Stereotype='dBusinessUseCase'
AND connector.Stereotype='Contains Activities'