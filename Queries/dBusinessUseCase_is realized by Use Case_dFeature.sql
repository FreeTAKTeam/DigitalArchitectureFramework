-- Generated 2022-12-20 12:18:57 PM
--  dBusinessUseCase (GroupName) connected with  dFeature (series)
SELECT dBusinessUseCase.Name as dBusinessUseCase,  dFeature.Name as  dFeature
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON dBusinessUseCase.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dFeature ON connector.End_Object_ID =  dFeature.Object_ID
WHERE dBusinessUseCase.Stereotype='dFeature'
AND  dFeature.Stereotype='dBusinessUseCase'
AND connector.Stereotype='is realized by Use Case'