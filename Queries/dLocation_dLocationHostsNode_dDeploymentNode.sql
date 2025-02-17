-- Generated 2025-01-15 3:36:39 PM
--  dLocation (GroupName) connected with  dDeploymentNode (series)
SELECT dLocation.Name as dLocation,  dDeploymentNode.Name as  dDeploymentNode
FROM t_object AS dDeploymentNode
INNER JOIN t_connector as connector ON dDeploymentNode.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dLocation ON connector.End_Object_ID =  dLocation.Object_ID
WHERE dLocation.Stereotype='dLocation'
AND  dDeploymentNode.Stereotype='dDeploymentNode'
AND connector.Stereotype='dLocationHostsNode'