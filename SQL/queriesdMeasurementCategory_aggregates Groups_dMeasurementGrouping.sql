-- Generated 10/24/2022 2:14:17 PM
--  dMeasurementCategory (GroupName) connected with  dMeasurementGrouping (series)
SELECT dMeasurementCategory.Name as dMeasurementCategory,  dMeasurementGrouping.Name as  dMeasurementGrouping
FROM t_object AS dMeasurementCategory
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dMeasurementGrouping.Object_ID
WHERE dMeasurementCategory.Stereotype='dMeasurementGrouping'
AND  dMeasurementGrouping.Stereotype='dMeasurementCategory'
AND connector.Stereotype='aggregates Groups'