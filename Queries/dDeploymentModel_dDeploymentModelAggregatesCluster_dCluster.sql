-- Generated 2024-09-10 10:59:20 AM
--  dDeploymentModel (GroupName) connected with  dCluster (series)
SELECT dDeploymentModel.Name as dDeploymentModel,  dCluster.Name as  dCluster
FROM t_object AS dCluster
INNER JOIN t_connector as connector ON dCluster.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDeploymentModel ON connector.End_Object_ID =  dDeploymentModel.Object_ID
WHERE dDeploymentModel.Stereotype='dDeploymentModel'
AND  dCluster.Stereotype='dCluster'
AND connector.Stereotype='dDeploymentModelAggregatesCluster'