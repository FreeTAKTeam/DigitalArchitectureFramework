-- Generated 2024-09-06 11:37:02 AM
--  dRisk (GroupName) connected with  dResource (series)
SELECT dRisk.Name as dRisk,  dResource.Name as  dResource
FROM t_object AS dResource
INNER JOIN t_connector as connector ON dResource.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRisk ON connector.End_Object_ID =  dRisk.Object_ID
WHERE dRisk.Stereotype='dRisk'
AND  dResource.Stereotype='dResource'
AND connector.Stereotype='Resource Risk'