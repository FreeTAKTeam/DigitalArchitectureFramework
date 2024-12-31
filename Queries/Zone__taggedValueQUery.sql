SELECT Zone.Object_ID, Zone.ea_guid AS CLASSGUID , Zone.Object_Type AS CLASSTYPE, Zone.Name as Zone
FROM t_object as Zone
 WHERE Zone.stereotype= 'dZone'