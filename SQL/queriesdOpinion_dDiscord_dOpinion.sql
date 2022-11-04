-- Generated 10/24/2022 2:15:01 PM
--  dOpinion (GroupName) connected with  dOpinion (series)
SELECT dOpinion.Name as dOpinion,  dOpinion.Name as  dOpinion
FROM t_object AS dOpinion
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dOpinion.Object_ID
WHERE dOpinion.Stereotype='dOpinion'
AND  dOpinion.Stereotype='dOpinion'
AND connector.Stereotype='dDiscord'