SELECT DeploymentModel.Object_ID, DeploymentModel.ea_guid AS CLASSGUID , DeploymentModel.Object_Type AS CLASSTYPE, DeploymentModel.Name as DeploymentModel
FROM t_object as DeploymentModel
 WHERE DeploymentModel.stereotype= 'dDeploymentModel'