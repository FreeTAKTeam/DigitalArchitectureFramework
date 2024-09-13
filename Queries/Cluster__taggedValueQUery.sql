SELECT Cluster.Object_ID, Cluster.ea_guid AS CLASSGUID , Cluster.Object_Type AS CLASSTYPE, Cluster.Name as Cluster
FROM t_object as Cluster
 WHERE Cluster.stereotype= 'dCluster'