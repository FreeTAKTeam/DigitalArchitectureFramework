SELECT MeasurementArea.Object_ID, MeasurementArea.ea_guid AS CLASSGUID , MeasurementArea.Object_Type AS CLASSTYPE, MeasurementArea.Name as MeasurementArea, ID.value, Definition.value
FROM t_object as MeasurementArea
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =MeasurementArea.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Definition  ON (Definition.Object_ID =MeasurementArea.Object_ID AND Definition.Property = ('Definition'))
 WHERE MeasurementArea.stereotype= 'dMeasurementArea'