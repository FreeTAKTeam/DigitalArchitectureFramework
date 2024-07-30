SELECT Object.Object_ID, Object.ea_guid AS CLASSGUID , Object.Object_Type AS CLASSTYPE, Object.Name as Object
FROM t_object as Object
 WHERE Object.stereotype= 'dObject'