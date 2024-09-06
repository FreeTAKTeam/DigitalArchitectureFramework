SELECT LogicalAppComponent.Object_ID, LogicalAppComponent.ea_guid AS CLASSGUID , LogicalAppComponent.Object_Type AS CLASSTYPE, LogicalAppComponent.Name as LogicalAppComponent, isUsable.value, meetsBizNeeds.value, meetsTomorrowNeeds.value
FROM t_object as LogicalAppComponent
INNER JOIN t_objectproperties AS isUsable  ON (isUsable.Object_ID =LogicalAppComponent.Object_ID AND isUsable.Property = ('isUsable'))
INNER JOIN t_objectproperties AS meetsBizNeeds  ON (meetsBizNeeds.Object_ID =LogicalAppComponent.Object_ID AND meetsBizNeeds.Property = ('meetsBizNeeds'))
INNER JOIN t_objectproperties AS meetsTomorrowNeeds  ON (meetsTomorrowNeeds.Object_ID =LogicalAppComponent.Object_ID AND meetsTomorrowNeeds.Property = ('meetsTomorrowNeeds'))
 WHERE LogicalAppComponent.stereotype= 'dLogicalAppComponent'