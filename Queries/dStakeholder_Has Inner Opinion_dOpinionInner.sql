-- Generated 2024-09-06 11:37:40 AM
--  dStakeholder (GroupName) connected with  dOpinionInner (series)
SELECT dStakeholder.Name as dStakeholder,  dOpinionInner.Name as  dOpinionInner
FROM t_object AS dOpinionInner
INNER JOIN t_connector as connector ON dOpinionInner.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dStakeholder ON connector.End_Object_ID =  dStakeholder.Object_ID
WHERE dStakeholder.Stereotype='dStakeholder'
AND  dOpinionInner.Stereotype='dOpinionInner'
AND connector.Stereotype='Has Inner Opinion'