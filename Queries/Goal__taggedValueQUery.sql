SELECT Goal.Object_ID, Goal.ea_guid AS CLASSGUID , Goal.Object_Type AS CLASSTYPE, Goal.Name as Goal, ID.value, Valueamount.value, ValueGoal.value, Priority.value, ValueName.value, dAssumption.value
FROM t_object as Goal
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Goal.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Valueamount  ON (Valueamount.Object_ID =Goal.Object_ID AND Valueamount.Property = ('Value_amount'))
INNER JOIN t_objectproperties AS ValueGoal  ON (ValueGoal.Object_ID =Goal.Object_ID AND ValueGoal.Property = ('Value_Goal'))
INNER JOIN t_objectproperties AS Priority  ON (Priority.Object_ID =Goal.Object_ID AND Priority.Property = ('Priority'))
INNER JOIN t_objectproperties AS ValueName  ON (ValueName.Object_ID =Goal.Object_ID AND ValueName.Property = ('Value_Name'))
INNER JOIN t_objectproperties AS dAssumption  ON (dAssumption.Object_ID =Goal.Object_ID AND dAssumption.Property = ('dAssumption'))
 WHERE Goal.stereotype= 'dGoal'