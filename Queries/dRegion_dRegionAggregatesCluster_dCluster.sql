-- Generated 2024-12-10 1:14:08 PM
--  dRegion (GroupName) connected with  dCluster (series)
SELECT dRegion.Name as dRegion,  dCluster.Name as  dCluster
FROM t_object AS dCluster
INNER JOIN t_connector as connector ON dCluster.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRegion ON connector.End_Object_ID =  dRegion.Object_ID
WHERE dRegion.Stereotype='dRegion'
AND  dCluster.Stereotype='dCluster'
AND connector.Stereotype='dRegionAggregatesCluster'