SELECT
    OpenAPI.Object_ID,
    OpenAPI.ea_guid AS CLASSGUID,
    OpenAPI.Object_Type AS CLASSTYPE,
    OpenAPI.Name AS OpenAPI,
    swagger.value AS swagger,
    ahost.value AS host,
    basePath.value AS basePath,
    schemes.value AS schemes,
    consumes.value AS consumes,
    produces.value AS produces,
    definitions.value AS definitions,
    aparameters.value AS aparameters,
    responses.value AS responses,
    securityDefinitions.value AS securityDefinitions,
    ID.value AS ID,
    tags.value AS tags,
    FullName.value AS FullName
	
FROM
    t_object AS OpenAPI
INNER JOIN t_objectproperties AS swagger
    ON swagger.Object_ID = OpenAPI.Object_ID AND swagger.Property = 'swagger'
INNER JOIN t_objectproperties AS ahost
    ON ahost.Object_ID = OpenAPI.Object_ID AND ahost.Property = 'host'
INNER JOIN t_objectproperties AS basePath
    ON basePath.Object_ID = OpenAPI.Object_ID AND basePath.Property = 'basePath'
INNER JOIN t_objectproperties AS schemes
    ON schemes.Object_ID = OpenAPI.Object_ID AND schemes.Property = 'schemes'
INNER JOIN t_objectproperties AS consumes
    ON consumes.Object_ID = OpenAPI.Object_ID AND consumes.Property = 'consumes'
INNER JOIN t_objectproperties AS produces
    ON produces.Object_ID = OpenAPI.Object_ID AND produces.Property = 'produces'
INNER JOIN t_objectproperties AS definitions
    ON definitions.Object_ID = OpenAPI.Object_ID AND definitions.Property = 'definitions'
INNER JOIN t_objectproperties AS aparameters
    ON aparameters.Object_ID = OpenAPI.Object_ID AND aparameters.Property = 'parameters'
INNER JOIN t_objectproperties AS responses
    ON responses.Object_ID = OpenAPI.Object_ID AND responses.Property = 'responses'
INNER JOIN t_objectproperties AS securityDefinitions
    ON securityDefinitions.Object_ID = OpenAPI.Object_ID AND securityDefinitions.Property = 'securityDefinitions'
INNER JOIN t_objectproperties AS ID
    ON ID.Object_ID = OpenAPI.Object_ID AND ID.Property = 'ID'
INNER JOIN t_objectproperties AS tags
    ON tags.Object_ID = OpenAPI.Object_ID AND tags.Property = 'tags'
INNER JOIN t_objectproperties AS FullName
    ON FullName.Object_ID = OpenAPI.Object_ID AND FullName.Property = 'Full Name'
WHERE
    OpenAPI.stereotype = 'dAPI';
