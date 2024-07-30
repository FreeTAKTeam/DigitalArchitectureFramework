SELECT Measurement Grouping.Object_ID, Measurement Grouping.ea_guid AS CLASSGUID , Measurement Grouping.Object_Type AS CLASSTYPE, Measurement Grouping.Name as Measurement Grouping, MeasurementCategory.value, Definition.value, ID.value
FROM t_object as Measurement Grouping
INNER JOIN t_objectproperties AS MeasurementCategory  ON (MeasurementCategory.Object_ID =Measurement Grouping.Object_ID AND MeasurementCategory.Property = ('MeasurementCategory'))
INNER JOIN t_objectproperties AS Definition  ON (Definition.Object_ID =Measurement Grouping.Object_ID AND Definition.Property = ('Definition'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Measurement Grouping.Object_ID AND ID.Property = ('ID'))
 WHERE Measurement Grouping.stereotype= 'dMeasurementGrouping'