SELECT JSONElement.Object_ID, JSONElement.ea_guid AS CLASSGUID , JSONElement.Object_Type AS CLASSTYPE, JSONElement.Name as JSONElement, id.value AS 'id'
FROM t_object as JSONElement
INNER JOIN t_objectproperties AS id  ON (id.Object_ID =JSONElement.Object_ID AND id.Property = ('id'))
 WHERE JSONElement.stereotype= 'dJSON_Element'