SELECT Region.Object_ID, Region.ea_guid AS CLASSGUID , Region.Object_Type AS CLASSTYPE, Region.Name as Region
FROM t_object as Region
 WHERE Region.stereotype= 'dRegion'