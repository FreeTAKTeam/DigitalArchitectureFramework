SELECT BusinessUseCase.Object_ID, BusinessUseCase.ea_guid AS CLASSGUID , BusinessUseCase.Object_Type AS CLASSTYPE, BusinessUseCase.Name as BusinessUseCase, GoalInContext.value AS 'GoalInContext', ID.value AS 'ID', GoalInContext.value AS 'GoalInContext', Precondition.value AS 'Precondition', Precondition.value AS 'Precondition', Trigger.value AS 'Trigger', Scope.value AS 'Scope', Trigger.value AS 'Trigger', Level.value AS 'Level', Scope.value AS 'Scope', Level.value AS 'Level', OtherActors.value AS 'OtherActors', OtherActors.value AS 'OtherActors', MainSuccessScenario.value AS 'MainSuccessScenario', Extensions.value AS 'Extensions', MainSuccessScenario.value AS 'MainSuccessScenario', Extensions.value AS 'Extensions', isCore.value AS 'isCore', isCore.value AS 'isCore'
FROM t_object as BusinessUseCase
INNER JOIN t_objectproperties AS GoalInContext  ON (GoalInContext.Object_ID =BusinessUseCase.Object_ID AND GoalInContext.Property = ('GoalInContext'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =BusinessUseCase.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS GoalInContext  ON (GoalInContext.Object_ID =BusinessUseCase.Object_ID AND GoalInContext.Property = ('GoalInContext'))
INNER JOIN t_objectproperties AS Precondition  ON (Precondition.Object_ID =BusinessUseCase.Object_ID AND Precondition.Property = ('Precondition'))
INNER JOIN t_objectproperties AS Precondition  ON (Precondition.Object_ID =BusinessUseCase.Object_ID AND Precondition.Property = ('Precondition'))
INNER JOIN t_objectproperties AS Trigger  ON (Trigger.Object_ID =BusinessUseCase.Object_ID AND Trigger.Property = ('Trigger'))
INNER JOIN t_objectproperties AS Scope  ON (Scope.Object_ID =BusinessUseCase.Object_ID AND Scope.Property = ('Scope'))
INNER JOIN t_objectproperties AS Trigger  ON (Trigger.Object_ID =BusinessUseCase.Object_ID AND Trigger.Property = ('Trigger'))
INNER JOIN t_objectproperties AS Level  ON (Level.Object_ID =BusinessUseCase.Object_ID AND Level.Property = ('Level'))
INNER JOIN t_objectproperties AS Scope  ON (Scope.Object_ID =BusinessUseCase.Object_ID AND Scope.Property = ('Scope'))
INNER JOIN t_objectproperties AS Level  ON (Level.Object_ID =BusinessUseCase.Object_ID AND Level.Property = ('Level'))
INNER JOIN t_objectproperties AS OtherActors  ON (OtherActors.Object_ID =BusinessUseCase.Object_ID AND OtherActors.Property = ('OtherActors'))
INNER JOIN t_objectproperties AS OtherActors  ON (OtherActors.Object_ID =BusinessUseCase.Object_ID AND OtherActors.Property = ('OtherActors'))
INNER JOIN t_objectproperties AS MainSuccessScenario  ON (MainSuccessScenario.Object_ID =BusinessUseCase.Object_ID AND MainSuccessScenario.Property = ('MainSuccessScenario'))
INNER JOIN t_objectproperties AS Extensions  ON (Extensions.Object_ID =BusinessUseCase.Object_ID AND Extensions.Property = ('Extensions'))
INNER JOIN t_objectproperties AS MainSuccessScenario  ON (MainSuccessScenario.Object_ID =BusinessUseCase.Object_ID AND MainSuccessScenario.Property = ('MainSuccessScenario'))
INNER JOIN t_objectproperties AS Extensions  ON (Extensions.Object_ID =BusinessUseCase.Object_ID AND Extensions.Property = ('Extensions'))
INNER JOIN t_objectproperties AS isCore  ON (isCore.Object_ID =BusinessUseCase.Object_ID AND isCore.Property = ('isCore'))
INNER JOIN t_objectproperties AS isCore  ON (isCore.Object_ID =BusinessUseCase.Object_ID AND isCore.Property = ('isCore'))
 WHERE BusinessUseCase.stereotype= 'dBusinessUseCase'