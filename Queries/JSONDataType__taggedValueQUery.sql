SELECT JSONDataType.Object_ID, JSONDataType.ea_guid AS CLASSGUID , JSONDataType.Object_Type AS CLASSTYPE, JSONDataType.Name as JSONDataType
FROM t_object as JSONDataType
 WHERE JSONDataType.stereotype= 'dJSON_Datatype'