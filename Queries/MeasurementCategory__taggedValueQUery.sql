SELECT MeasurementCategory.Object_ID, MeasurementCategory.ea_guid AS CLASSGUID , MeasurementCategory.Object_Type AS CLASSTYPE, MeasurementCategory.Name as MeasurementCategory, MeasurementArea.value, Definition.value, ID.value
FROM t_object as MeasurementCategory
INNER JOIN t_objectproperties AS MeasurementArea  ON (MeasurementArea.Object_ID =MeasurementCategory.Object_ID AND MeasurementArea.Property = ('MeasurementArea'))
INNER JOIN t_objectproperties AS Definition  ON (Definition.Object_ID =MeasurementCategory.Object_ID AND Definition.Property = ('Definition'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =MeasurementCategory.Object_ID AND ID.Property = ('ID'))
 WHERE MeasurementCategory.stereotype= 'dMeasurementCategory'