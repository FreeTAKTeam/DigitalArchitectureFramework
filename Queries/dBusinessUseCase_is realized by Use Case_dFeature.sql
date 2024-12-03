-- Generated 2024-12-03 2:07:08 PM
--  dBusinessUseCase (GroupName) connected with  dFeature (series)
SELECT dBusinessUseCase.Name as dBusinessUseCase,  dFeature.Name as  dFeature
FROM t_object AS dFeature
INNER JOIN t_connector as connector ON dFeature.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessUseCase ON connector.End_Object_ID =  dBusinessUseCase.Object_ID
WHERE dBusinessUseCase.Stereotype='dBusinessUseCase'
AND  dFeature.Stereotype='dFeature'
AND connector.Stereotype='is realized by Use Case'