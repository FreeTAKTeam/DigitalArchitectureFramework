-- Generated 2024-09-10 11:04:12 AM
--  dMeasurementCategory (GroupName) connected with  dMeasurementGrouping (series)
SELECT dMeasurementCategory.Name as dMeasurementCategory,  dMeasurementGrouping.Name as  dMeasurementGrouping
FROM t_object AS dMeasurementGrouping
INNER JOIN t_connector as connector ON dMeasurementGrouping.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dMeasurementCategory ON connector.End_Object_ID =  dMeasurementCategory.Object_ID
WHERE dMeasurementCategory.Stereotype='dMeasurementCategory'
AND  dMeasurementGrouping.Stereotype='dMeasurementGrouping'
AND connector.Stereotype='aggregates Groups'