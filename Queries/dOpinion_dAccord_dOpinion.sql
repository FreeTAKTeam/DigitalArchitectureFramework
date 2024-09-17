-- Generated 2024-09-16 2:08:46 PM
--  dOpinion (GroupName) connected with  dOpinion (series)
SELECT dOpinion.Name as dOpinion,  dOpinion.Name as  dOpinion
FROM t_object AS dOpinion
INNER JOIN t_connector as connector ON dOpinion.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dOpinion ON connector.End_Object_ID =  dOpinion.Object_ID
WHERE dOpinion.Stereotype='dOpinion'
AND  dOpinion.Stereotype='dOpinion'
AND connector.Stereotype='dAccord'