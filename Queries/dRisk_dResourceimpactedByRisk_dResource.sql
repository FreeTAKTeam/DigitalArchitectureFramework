-- Generated 2025-01-15 3:39:40 PM
--  dRisk (GroupName) connected with  dResource (series)
SELECT dRisk.Name as dRisk,  dResource.Name as  dResource
FROM t_object AS dResource
INNER JOIN t_connector as connector ON dResource.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRisk ON connector.End_Object_ID =  dRisk.Object_ID
WHERE dRisk.Stereotype='dRisk'
AND  dResource.Stereotype='dResource'
AND connector.Stereotype='dResourceimpactedByRisk'