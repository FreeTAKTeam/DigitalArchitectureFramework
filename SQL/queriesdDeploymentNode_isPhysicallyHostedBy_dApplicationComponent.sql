-- Generated 10/24/2022 2:13:15 PM
--  dDeploymentNode (GroupName) connected with  dApplicationComponent (series)
SELECT dDeploymentNode.Name as dDeploymentNode,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dDeploymentNode
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dDeploymentNode.Stereotype='dApplicationComponent'
AND  dApplicationComponent.Stereotype='dDeploymentNode'
AND connector.Stereotype='isPhysicallyHostedBy'