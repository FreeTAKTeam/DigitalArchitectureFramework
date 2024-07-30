SELECT Role.Object_ID, Role.ea_guid AS CLASSGUID , Role.Object_Type AS CLASSTYPE, Role.Name as Role, FTEs.value, User.value, ID.value, Owner.value, Source.value, DegreeOfUtilisation.value, Cost.value
FROM t_object as Role
INNER JOIN t_objectproperties AS FTEs  ON (FTEs.Object_ID =Role.Object_ID AND FTEs.Property = ('#FTEs'))
INNER JOIN t_objectproperties AS User  ON (User.Object_ID =Role.Object_ID AND User.Property = ('User'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Role.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =Role.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =Role.Object_ID AND Source.Property = ('Source'))
INNER JOIN t_objectproperties AS DegreeOfUtilisation  ON (DegreeOfUtilisation.Object_ID =Role.Object_ID AND DegreeOfUtilisation.Property = ('DegreeOfUtilisation'))
INNER JOIN t_objectproperties AS Cost  ON (Cost.Object_ID =Role.Object_ID AND Cost.Property = ('Cost'))
 WHERE Role.stereotype= 'dRole'