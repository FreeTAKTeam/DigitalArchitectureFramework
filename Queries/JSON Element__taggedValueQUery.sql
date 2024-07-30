SELECT JSON Element.Object_ID, JSON Element.ea_guid AS CLASSGUID , JSON Element.Object_Type AS CLASSTYPE, JSON Element.Name as JSON Element, id.value
FROM t_object as JSON Element
INNER JOIN t_objectproperties AS id  ON (id.Object_ID =JSON Element.Object_ID AND id.Property = ('id'))
 WHERE JSON Element.stereotype= 'dJSON_Element'