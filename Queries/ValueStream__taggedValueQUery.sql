SELECT ValueStream.Object_ID, ValueStream.ea_guid AS CLASSGUID , ValueStream.Object_Type AS CLASSTYPE, ValueStream.Name as ValueStream, Criticality.value AS Criticality, isDecomposed.value AS isDecomposed, entrancecriteria.value AS entrancecriteria, exitcriteria.value AS exitcriteria
FROM t_object as ValueStream
INNER JOIN t_objectproperties AS Criticality  ON (Criticality.Object_ID =ValueStream.Object_ID AND Criticality.Property = ('Criticality'))
INNER JOIN t_objectproperties AS isDecomposed  ON (isDecomposed.Object_ID =ValueStream.Object_ID AND isDecomposed.Property = ('is Decomposed'))
INNER JOIN t_objectproperties AS entrancecriteria  ON (entrancecriteria.Object_ID =ValueStream.Object_ID AND entrancecriteria.Property = ('entrance criteria'))
INNER JOIN t_objectproperties AS exitcriteria  ON (exitcriteria.Object_ID =ValueStream.Object_ID AND exitcriteria.Property = ('exit criteria'))
 WHERE ValueStream.stereotype= 'dValueStream'