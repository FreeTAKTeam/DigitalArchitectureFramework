-- Generated 2022-12-20 12:24:11 PM
--  dStakeholder (GroupName) connected with  dOpinionInner (series)
SELECT dStakeholder.Name as dStakeholder,  dOpinionInner.Name as  dOpinionInner
FROM t_object AS dStakeholder
INNER JOIN t_connector as connector ON dStakeholder.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dOpinionInner ON connector.End_Object_ID =  dOpinionInner.Object_ID
WHERE dStakeholder.Stereotype='dOpinionInner'
AND  dOpinionInner.Stereotype='dStakeholder'
AND connector.Stereotype='Has Inner Opinion'