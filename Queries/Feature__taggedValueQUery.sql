SELECT Feature.Object_ID, Feature.ea_guid AS CLASSGUID , Feature.Object_Type AS CLASSTYPE, Feature.Name as Feature, Author.value, Proofreader.value, Status.value
FROM t_object as Feature
INNER JOIN t_objectproperties AS Author  ON (Author.Object_ID =Feature.Object_ID AND Author.Property = ('Author'))
INNER JOIN t_objectproperties AS Proofreader  ON (Proofreader.Object_ID =Feature.Object_ID AND Proofreader.Property = ('Proofreader'))
INNER JOIN t_objectproperties AS Status  ON (Status.Object_ID =Feature.Object_ID AND Status.Property = ('Status'))
 WHERE Feature.stereotype= 'dFeature'