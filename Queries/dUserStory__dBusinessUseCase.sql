-- Generated 2022-12-20 12:24:32 PM
--  dUserStory (GroupName) connected with  dBusinessUseCase (series)
SELECT dUserStory.Name as dUserStory,  dBusinessUseCase.Name as  dBusinessUseCase
FROM t_object AS dUserStory
INNER JOIN t_connector as connector ON dUserStory.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessUseCase ON connector.End_Object_ID =  dBusinessUseCase.Object_ID
WHERE dUserStory.Stereotype='dBusinessUseCase'
AND  dBusinessUseCase.Stereotype='dUserStory'
AND connector.Stereotype=''