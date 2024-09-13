-- Generated 2024-09-09 5:53:33 PM
--  DeploymentModel (GroupName) connected with  dCluster (series)
SELECT DeploymentModel.Name as DeploymentModel,  dCluster.Name as  dCluster
FROM t_object AS dCluster
INNER JOIN t_connector as connector ON dCluster.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS DeploymentModel ON connector.End_Object_ID =  DeploymentModel.Object_ID
WHERE DeploymentModel.Stereotype='DeploymentModel'
AND  dCluster.Stereotype='dCluster'
AND connector.Stereotype=''