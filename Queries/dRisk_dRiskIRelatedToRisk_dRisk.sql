-- Generated 2025-01-15 3:39:37 PM
--  dRisk (GroupName) connected with  dRisk (series)
SELECT dRisk.Name as dRisk,  dRisk.Name as  dRisk
FROM t_object AS dRisk
INNER JOIN t_connector as connector ON dRisk.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRisk ON connector.End_Object_ID =  dRisk.Object_ID
WHERE dRisk.Stereotype='dRisk'
AND  dRisk.Stereotype='dRisk'
AND connector.Stereotype='dRiskIRelatedToRisk'