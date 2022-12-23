-- Generated 2022-12-20 12:21:15 PM
--  dLocation (GroupName) connected with  dDeploymentNode (series)
SELECT dLocation.Name as dLocation,  dDeploymentNode.Name as  dDeploymentNode
FROM t_object AS dLocation
INNER JOIN t_connector as connector ON dLocation.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDeploymentNode ON connector.End_Object_ID =  dDeploymentNode.Object_ID
WHERE dLocation.Stereotype='dDeploymentNode'
AND  dDeploymentNode.Stereotype='dLocation'
AND connector.Stereotype='Hosts Node'