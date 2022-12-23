-- Generated 2022-12-20 12:23:51 PM
--  dRisk (GroupName) connected with  dResource (series)
SELECT dRisk.Name as dRisk,  dResource.Name as  dResource
FROM t_object AS dRisk
INNER JOIN t_connector as connector ON dRisk.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dResource ON connector.End_Object_ID =  dResource.Object_ID
WHERE dRisk.Stereotype='dResource'
AND  dResource.Stereotype='dRisk'
AND connector.Stereotype='Resource Risk'