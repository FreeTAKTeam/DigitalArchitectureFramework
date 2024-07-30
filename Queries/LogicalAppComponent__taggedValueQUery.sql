SELECT LogicalAppComponent.Object_ID, LogicalAppComponent.ea_guid AS CLASSGUID , LogicalAppComponent.Object_Type AS CLASSTYPE, LogicalAppComponent.Name as LogicalAppComponent
FROM t_object as LogicalAppComponent
 WHERE LogicalAppComponent.stereotype= 'dLogicalAppComponent'