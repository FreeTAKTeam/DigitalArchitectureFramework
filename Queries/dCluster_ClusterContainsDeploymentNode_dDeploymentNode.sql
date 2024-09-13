-- Generated 2024-09-10 10:57:29 AM
--  dCluster (GroupName) connected with  dDeploymentNode (series)
SELECT dCluster.Name as dCluster,  dDeploymentNode.Name as  dDeploymentNode
FROM t_object AS dDeploymentNode
INNER JOIN t_connector as connector ON dDeploymentNode.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCluster ON connector.End_Object_ID =  dCluster.Object_ID
WHERE dCluster.Stereotype='dCluster'
AND  dDeploymentNode.Stereotype='dDeploymentNode'
AND connector.Stereotype='ClusterContainsDeploymentNode'