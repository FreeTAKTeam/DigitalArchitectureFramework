-- Generated 2024-09-16 2:11:06 PM
--  dPublicCluster (GroupName) connected with  dCluster (series)
SELECT dPublicCluster.Name as dPublicCluster,  dCluster.Name as  dCluster
FROM t_object AS dCluster
INNER JOIN t_connector as connector ON dCluster.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dPublicCluster ON connector.End_Object_ID =  dPublicCluster.Object_ID
WHERE dPublicCluster.Stereotype='dPublicCluster'
AND  dCluster.Stereotype='dCluster'
AND connector.Stereotype='dPublicClustergeneralizesCluster'