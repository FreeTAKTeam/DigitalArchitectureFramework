-- Generated 2024-07-30 3:24:49 PM
--  dMeasurementArea (GroupName) connected with  dMeasurementCategory (series)
SELECT dMeasurementArea.Name as dMeasurementArea,  dMeasurementCategory.Name as  dMeasurementCategory
FROM t_object AS dMeasurementCategory
INNER JOIN t_connector as connector ON dMeasurementCategory.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dMeasurementArea ON connector.End_Object_ID =  dMeasurementArea.Object_ID
WHERE dMeasurementArea.Stereotype='dMeasurementArea'
AND  dMeasurementCategory.Stereotype='dMeasurementCategory'
AND connector.Stereotype='aggregates categories'