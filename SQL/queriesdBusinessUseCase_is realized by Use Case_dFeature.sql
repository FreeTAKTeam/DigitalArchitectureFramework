-- Generated 10/24/2022 2:12:18 PM
--  dBusinessUseCase (GroupName) connected with  dFeature (series)
SELECT dBusinessUseCase.Name as dBusinessUseCase,  dFeature.Name as  dFeature
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dFeature.Object_ID
WHERE dBusinessUseCase.Stereotype='dFeature'
AND  dFeature.Stereotype='dBusinessUseCase'
AND connector.Stereotype='is realized by Use Case'


SELECT dBusinessUseCase.Name as dBusinessUseCase,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON dBusinessUseCase.Object_ID = connector.End_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.Start_Object_ID =  dApplicationComponent.Object_ID
WHERE dBusinessUseCase.Stereotype='dApplicationComponent'
AND  dApplicationComponent.Stereotype='dBusinessUseCase'
AND connector.type='realization'
AND dBusinessUseCase.version = 2.0