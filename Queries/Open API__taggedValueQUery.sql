SELECT Open API.Object_ID, Open API.ea_guid AS CLASSGUID , Open API.Object_Type AS CLASSTYPE, Open API.Name as Open API, swagger.value, host.value, basePath.value, schemes.value, consumes.value, produces.value, definitions.value, parameters.value, responses.value, securityDefinitions.value, ID.value, tags.value, FullName.value
FROM t_object as Open API
INNER JOIN t_objectproperties AS swagger  ON (swagger.Object_ID =Open API.Object_ID AND swagger.Property = ('swagger'))
INNER JOIN t_objectproperties AS host  ON (host.Object_ID =Open API.Object_ID AND host.Property = ('host'))
INNER JOIN t_objectproperties AS basePath  ON (basePath.Object_ID =Open API.Object_ID AND basePath.Property = ('basePath'))
INNER JOIN t_objectproperties AS schemes  ON (schemes.Object_ID =Open API.Object_ID AND schemes.Property = ('schemes'))
INNER JOIN t_objectproperties AS consumes  ON (consumes.Object_ID =Open API.Object_ID AND consumes.Property = ('consumes'))
INNER JOIN t_objectproperties AS produces  ON (produces.Object_ID =Open API.Object_ID AND produces.Property = ('produces'))
INNER JOIN t_objectproperties AS definitions  ON (definitions.Object_ID =Open API.Object_ID AND definitions.Property = ('definitions'))
INNER JOIN t_objectproperties AS parameters  ON (parameters.Object_ID =Open API.Object_ID AND parameters.Property = ('parameters'))
INNER JOIN t_objectproperties AS responses  ON (responses.Object_ID =Open API.Object_ID AND responses.Property = ('responses'))
INNER JOIN t_objectproperties AS securityDefinitions  ON (securityDefinitions.Object_ID =Open API.Object_ID AND securityDefinitions.Property = ('securityDefinitions'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Open API.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS tags  ON (tags.Object_ID =Open API.Object_ID AND tags.Property = ('tags'))
INNER JOIN t_objectproperties AS FullName  ON (FullName.Object_ID =Open API.Object_ID AND FullName.Property = ('Full Name'))
 WHERE Open API.stereotype= 'dAPI'