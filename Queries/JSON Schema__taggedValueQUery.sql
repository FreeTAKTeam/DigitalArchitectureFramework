SELECT JSON Schema.Object_ID, JSON Schema.ea_guid AS CLASSGUID , JSON Schema.Object_Type AS CLASSTYPE, JSON Schema.Name as JSON Schema, id.value, schema.value, schemaFileName.value
FROM t_object as JSON Schema
INNER JOIN t_objectproperties AS id  ON (id.Object_ID =JSON Schema.Object_ID AND id.Property = ('id'))
INNER JOIN t_objectproperties AS schema  ON (schema.Object_ID =JSON Schema.Object_ID AND schema.Property = ('schema'))
INNER JOIN t_objectproperties AS schemaFileName  ON (schemaFileName.Object_ID =JSON Schema.Object_ID AND schemaFileName.Property = ('schemaFileName'))
 WHERE JSON Schema.stereotype= 'dJSON_Schema'