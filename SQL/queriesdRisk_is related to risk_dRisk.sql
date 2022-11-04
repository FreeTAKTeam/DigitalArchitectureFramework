-- Generated 10/24/2022 2:15:58 PM
--  dRisk (GroupName) connected with  dRisk (series)
SELECT dRisk.Name as dRisk,  dRisk.Name as  dRisk
FROM t_object AS dRisk
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dRisk.Object_ID
WHERE dRisk.Stereotype='dRisk'
AND  dRisk.Stereotype='dRisk'
AND connector.Stereotype='is related to risk'