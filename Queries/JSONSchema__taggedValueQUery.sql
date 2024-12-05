SELECT JSONSchema.Object_ID, JSONSchema.ea_guid AS CLASSGUID , JSONSchema.Object_Type AS CLASSTYPE, JSONSchema.Name as JSONSchema, id.value AS id, schema.value AS schema, schemaFileName.value AS schemaFileName
FROM t_object as JSONSchema
INNER JOIN t_objectproperties AS id  ON (id.Object_ID =JSONSchema.Object_ID AND id.Property = ('id'))
INNER JOIN t_objectproperties AS schema  ON (schema.Object_ID =JSONSchema.Object_ID AND schema.Property = ('schema'))
INNER JOIN t_objectproperties AS schemaFileName  ON (schemaFileName.Object_ID =JSONSchema.Object_ID AND schemaFileName.Property = ('schemaFileName'))
 WHERE JSONSchema.stereotype= 'dJSON_Schema'