SELECT GrowthPackage.Object_ID, GrowthPackage.ea_guid AS CLASSGUID , GrowthPackage.Object_Type AS CLASSTYPE, GrowthPackage.Name as GrowthPackage
FROM t_object as GrowthPackage
 WHERE GrowthPackage.stereotype= 'dGrowthPackage'