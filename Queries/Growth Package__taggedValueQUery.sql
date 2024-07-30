SELECT Growth Package.Object_ID, Growth Package.ea_guid AS CLASSGUID , Growth Package.Object_Type AS CLASSTYPE, Growth Package.Name as Growth Package
FROM t_object as Growth Package
 WHERE Growth Package.stereotype= 'dGrowthPackage'