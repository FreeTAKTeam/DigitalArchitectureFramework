-- Generated 2022-12-20 12:21:31 PM
--  dMeasurementCategory (GroupName) connected with  dMeasurementGrouping (series)
SELECT dMeasurementCategory.Name as dMeasurementCategory,  dMeasurementGrouping.Name as  dMeasurementGrouping
FROM t_object AS dMeasurementCategory
INNER JOIN t_connector as connector ON dMeasurementCategory.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dMeasurementGrouping ON connector.End_Object_ID =  dMeasurementGrouping.Object_ID
WHERE dMeasurementCategory.Stereotype='dMeasurementGrouping'
AND  dMeasurementGrouping.Stereotype='dMeasurementCategory'
AND connector.Stereotype='aggregates Groups'