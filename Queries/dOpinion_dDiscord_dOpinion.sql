-- Generated 2022-12-20 12:22:29 PM
--  dOpinion (GroupName) connected with  dOpinion (series)
SELECT dOpinion.Name as dOpinion,  dOpinion.Name as  dOpinion
FROM t_object AS dOpinion
INNER JOIN t_connector as connector ON dOpinion.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dOpinion ON connector.End_Object_ID =  dOpinion.Object_ID
WHERE dOpinion.Stereotype='dOpinion'
AND  dOpinion.Stereotype='dOpinion'
AND connector.Stereotype='dDiscord'