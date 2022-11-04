-- Generated 10/24/2022 2:14:37 PM
--  dNetwork (GroupName) connected with  dDeploymentNode (series)
SELECT dNetwork.Name as dNetwork,  dDeploymentNode.Name as  dDeploymentNode
FROM t_object AS dNetwork
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dDeploymentNode.Object_ID
WHERE dNetwork.Stereotype='dDeploymentNode'
AND  dDeploymentNode.Stereotype='dNetwork'
AND connector.Stereotype='NetworkContainsNode'