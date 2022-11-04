-- Generated 10/24/2022 2:16:16 PM
--  dStakeholder (GroupName) connected with  dOpinionInner (series)
SELECT dStakeholder.Name as dStakeholder,  dOpinionInner.Name as  dOpinionInner
FROM t_object AS dStakeholder
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dOpinionInner.Object_ID
WHERE dStakeholder.Stereotype='dOpinionInner'
AND  dOpinionInner.Stereotype='dStakeholder'
AND connector.Stereotype='Has Inner Opinion'