SELECT Network.Object_ID, Network.ea_guid AS CLASSGUID , Network.Object_Type AS CLASSTYPE, Network.Name as Network, NetworkType.value, NetworkQuality.value
FROM t_object as Network
INNER JOIN t_objectproperties AS NetworkType  ON (NetworkType.Object_ID =Network.Object_ID AND NetworkType.Property = ('NetworkType'))
INNER JOIN t_objectproperties AS NetworkQuality  ON (NetworkQuality.Object_ID =Network.Object_ID AND NetworkQuality.Property = ('NetworkQuality'))
 WHERE Network.stereotype= 'dNetwork'