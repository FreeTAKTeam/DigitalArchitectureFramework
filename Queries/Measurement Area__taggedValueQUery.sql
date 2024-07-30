SELECT Measurement Area.Object_ID, Measurement Area.ea_guid AS CLASSGUID , Measurement Area.Object_Type AS CLASSTYPE, Measurement Area.Name as Measurement Area, ID.value, Definition.value
FROM t_object as Measurement Area
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Measurement Area.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Definition  ON (Definition.Object_ID =Measurement Area.Object_ID AND Definition.Property = ('Definition'))
 WHERE Measurement Area.stereotype= 'dMeasurementArea'