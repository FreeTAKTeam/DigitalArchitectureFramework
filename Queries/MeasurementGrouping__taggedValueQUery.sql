SELECT MeasurementGrouping.Object_ID, MeasurementGrouping.ea_guid AS CLASSGUID , MeasurementGrouping.Object_Type AS CLASSTYPE, MeasurementGrouping.Name as MeasurementGrouping, MeasurementCategory.value AS 'MeasurementCategory', Definition.value AS 'Definition', ID.value AS 'ID'
FROM t_object as MeasurementGrouping
INNER JOIN t_objectproperties AS MeasurementCategory  ON (MeasurementCategory.Object_ID =MeasurementGrouping.Object_ID AND MeasurementCategory.Property = ('MeasurementCategory'))
INNER JOIN t_objectproperties AS Definition  ON (Definition.Object_ID =MeasurementGrouping.Object_ID AND Definition.Property = ('Definition'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =MeasurementGrouping.Object_ID AND ID.Property = ('ID'))
 WHERE MeasurementGrouping.stereotype= 'dMeasurementGrouping'