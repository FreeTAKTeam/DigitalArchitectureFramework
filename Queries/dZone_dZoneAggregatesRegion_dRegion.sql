-- Generated 2024-12-31 1:09:21 PM
--  dZone (GroupName) connected with  dRegion (series)
SELECT dZone.Name as dZone,  dRegion.Name as  dRegion
FROM t_object AS dRegion
INNER JOIN t_connector as connector ON dRegion.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dZone ON connector.End_Object_ID =  dZone.Object_ID
WHERE dZone.Stereotype='dZone'
AND  dRegion.Stereotype='dRegion'
AND connector.Stereotype='dZoneAggregatesRegion'