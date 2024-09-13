SELECT SubNetwork.Object_ID, SubNetwork.ea_guid AS CLASSGUID , SubNetwork.Object_Type AS CLASSTYPE, SubNetwork.Name as SubNetwork
FROM t_object as SubNetwork
 WHERE SubNetwork.stereotype= 'dSubNetwork'