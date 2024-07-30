SELECT Test.Object_ID, Test.ea_guid AS CLASSGUID , Test.Object_Type AS CLASSTYPE, Test.Name as Test
FROM t_object as Test
 WHERE Test.stereotype= 'dTest'