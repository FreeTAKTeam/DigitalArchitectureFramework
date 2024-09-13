-- Generated 2024-09-10 11:13:32 AM
--  dUserStory (GroupName) connected with  dBusinessUseCase (series)
SELECT dUserStory.Name as dUserStory,  dBusinessUseCase.Name as  dBusinessUseCase
FROM t_object AS dBusinessUseCase
INNER JOIN t_connector as connector ON dBusinessUseCase.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dUserStory ON connector.End_Object_ID =  dUserStory.Object_ID
WHERE dUserStory.Stereotype='dUserStory'
AND  dBusinessUseCase.Stereotype='dBusinessUseCase'
AND connector.Stereotype=''