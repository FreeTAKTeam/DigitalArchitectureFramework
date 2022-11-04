-- Generated 10/24/2022 2:14:12 PM
--  dMeasurementArea (GroupName) connected with  dMeasurementCategory (series)
SELECT dMeasurementArea.Name as dMeasurementArea,  dMeasurementCategory.Name as  dMeasurementCategory
FROM t_object AS dMeasurementArea
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dMeasurementCategory.Object_ID
WHERE dMeasurementArea.Stereotype='dMeasurementCategory'
AND  dMeasurementCategory.Stereotype='dMeasurementArea'
AND connector.Stereotype='aggregates categories'