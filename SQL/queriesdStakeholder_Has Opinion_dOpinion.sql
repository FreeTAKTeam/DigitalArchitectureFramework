-- Generated 10/24/2022 2:16:18 PM
--  dStakeholder (GroupName) connected with  dOpinion (series)
SELECT dStakeholder.Name as dStakeholder,  dOpinion.Name as  dOpinion
FROM t_object AS dStakeholder
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dOpinion.Object_ID
WHERE dStakeholder.Stereotype='dOpinion'
AND  dOpinion.Stereotype='dStakeholder'
AND connector.Stereotype='Has Opinion'