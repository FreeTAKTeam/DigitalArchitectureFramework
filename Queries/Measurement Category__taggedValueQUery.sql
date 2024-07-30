SELECT Measurement Category.Object_ID, Measurement Category.ea_guid AS CLASSGUID , Measurement Category.Object_Type AS CLASSTYPE, Measurement Category.Name as Measurement Category, MeasurementArea.value, Definition.value, ID.value
FROM t_object as Measurement Category
INNER JOIN t_objectproperties AS MeasurementArea  ON (MeasurementArea.Object_ID =Measurement Category.Object_ID AND MeasurementArea.Property = ('MeasurementArea'))
INNER JOIN t_objectproperties AS Definition  ON (Definition.Object_ID =Measurement Category.Object_ID AND Definition.Property = ('Definition'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Measurement Category.Object_ID AND ID.Property = ('ID'))
 WHERE Measurement Category.stereotype= 'dMeasurementCategory'