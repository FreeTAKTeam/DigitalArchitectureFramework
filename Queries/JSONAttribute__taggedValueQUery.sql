SELECT JSONAttribute.Object_ID, JSONAttribute.ea_guid AS CLASSGUID , JSONAttribute.Object_Type AS CLASSTYPE, JSONAttribute.Name as JSONAttribute
FROM t_object as JSONAttribute
 WHERE JSONAttribute.stereotype= 'dJSON_Attribute'