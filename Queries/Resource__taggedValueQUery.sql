SELECT Resource.Object_ID, Resource.ea_guid AS CLASSGUID , Resource.Object_Type AS CLASSTYPE, Resource.Name as Resource, ofitems.value
FROM t_object as Resource
INNER JOIN t_objectproperties AS ofitems  ON (ofitems.Object_ID =Resource.Object_ID AND ofitems.Property = ('# of items'))
 WHERE Resource.stereotype= 'dResource'