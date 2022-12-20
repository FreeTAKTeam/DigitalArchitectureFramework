-- Generated 2022-12-20 12:24:15 PM
--  dStakeholder (GroupName) connected with  dOpinion (series)
SELECT dStakeholder.Name as dStakeholder,  dOpinion.Name as  dOpinion
FROM t_object AS dStakeholder
INNER JOIN t_connector as connector ON dStakeholder.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dOpinion ON connector.End_Object_ID =  dOpinion.Object_ID
WHERE dStakeholder.Stereotype='dOpinion'
AND  dOpinion.Stereotype='dStakeholder'
AND connector.Stereotype='Has Opinion'