SELECT dBusinessUseCase.Name as dBusinessUseCase,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON dBusinessUseCase.Object_ID = connector.End_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.Start_Object_ID =  dApplicationComponent.Object_ID
WHERE dBusinessUseCase.Stereotype='dBusinessUseCase'
AND  dApplicationComponent.Stereotype='dApplicationComponent'
AND connector.connector_type='realization'
AND dBusinessUseCase.version = '2.0'