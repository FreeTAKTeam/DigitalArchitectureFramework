-- Generated 2024-09-06 11:34:51 AM
--  dNetwork (GroupName) connected with  dDeploymentNode (series)
SELECT dNetwork.Name as dNetwork,  dDeploymentNode.Name as  dDeploymentNode
FROM t_object AS dDeploymentNode
INNER JOIN t_connector as connector ON dDeploymentNode.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dNetwork ON connector.End_Object_ID =  dNetwork.Object_ID
WHERE dNetwork.Stereotype='dNetwork'
AND  dDeploymentNode.Stereotype='dDeploymentNode'
AND connector.Stereotype='NetworkContainsNode'