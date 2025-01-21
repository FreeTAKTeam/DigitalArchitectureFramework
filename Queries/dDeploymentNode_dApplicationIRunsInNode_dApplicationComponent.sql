-- Generated 2025-01-15 3:34:55 PM
--  dDeploymentNode (GroupName) connected with  dApplicationComponent (series)
SELECT dDeploymentNode.Name as dDeploymentNode,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON dApplicationComponent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDeploymentNode ON connector.End_Object_ID =  dDeploymentNode.Object_ID
WHERE dDeploymentNode.Stereotype='dDeploymentNode'
AND  dApplicationComponent.Stereotype='dApplicationComponent'
AND connector.Stereotype='dApplicationIRunsInNode'