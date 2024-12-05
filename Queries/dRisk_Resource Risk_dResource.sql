-- Generated 2024-12-05 10:55:23 AM
--  dRisk (GroupName) connected with  dResource (series)
SELECT dRisk.Name as dRisk,  dResource.Name as  dResource
FROM t_object AS dResource
INNER JOIN t_connector as connector ON dResource.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRisk ON connector.End_Object_ID =  dRisk.Object_ID
WHERE dRisk.Stereotype='dRisk'
AND  dResource.Stereotype='dResource'
AND connector.Stereotype='Resource Risk'