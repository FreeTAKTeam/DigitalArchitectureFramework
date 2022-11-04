-- Generated 10/24/2022 2:16:00 PM
--  dRisk (GroupName) connected with  dResource (series)
SELECT dRisk.Name as dRisk,  dResource.Name as  dResource
FROM t_object AS dRisk
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dResource.Object_ID
WHERE dRisk.Stereotype='dResource'
AND  dResource.Stereotype='dRisk'
AND connector.Stereotype='Resource Risk'