-- Generated 2022-12-20 12:20:16 PM
--  dDeploymentNode (GroupName) connected with  dApplicationComponent (series)
SELECT dDeploymentNode.Name as dDeploymentNode,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dDeploymentNode
INNER JOIN t_connector as connector ON dDeploymentNode.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dDeploymentNode.Stereotype='dApplicationComponent'
AND  dApplicationComponent.Stereotype='dDeploymentNode'
AND connector.Stereotype='isPhysicallyHostedBy'