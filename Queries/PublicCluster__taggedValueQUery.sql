SELECT PublicCluster.Object_ID, PublicCluster.ea_guid AS CLASSGUID , PublicCluster.Object_Type AS CLASSTYPE, PublicCluster.Name as PublicCluster, provider.value AS provider, NodeNum.value AS NodeNum, configFile.value AS configFile
FROM t_object as PublicCluster
INNER JOIN t_objectproperties AS provider  ON (provider.Object_ID =PublicCluster.Object_ID AND provider.Property = ('provider'))
INNER JOIN t_objectproperties AS NodeNum  ON (NodeNum.Object_ID =PublicCluster.Object_ID AND NodeNum.Property = ('NodeNum'))
INNER JOIN t_objectproperties AS configFile  ON (configFile.Object_ID =PublicCluster.Object_ID AND configFile.Property = ('configFile'))
 WHERE PublicCluster.stereotype= 'dPublicCluster'