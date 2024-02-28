-- Generated 2024-02-28 10:51:30 AM
--  dStakeholder (GroupName) connected with  dOpinion (series)
SELECT dStakeholder.Name as dStakeholder,  dOpinion.Name as  dOpinion
FROM t_object AS dOpinion
INNER JOIN t_connector as connector ON dOpinion.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dStakeholder ON connector.End_Object_ID =  dStakeholder.Object_ID
WHERE dStakeholder.Stereotype='dStakeholder'
AND  dOpinion.Stereotype='dOpinion'
AND connector.Stereotype='Has Opinion'