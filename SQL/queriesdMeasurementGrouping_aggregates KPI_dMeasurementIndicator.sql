-- Generated 10/24/2022 2:14:22 PM
--  dMeasurementGrouping (GroupName) connected with  dMeasurementIndicator (series)
SELECT dMeasurementGrouping.Name as dMeasurementGrouping,  dMeasurementIndicator.Name as  dMeasurementIndicator
FROM t_object AS dMeasurementGrouping
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dMeasurementIndicator.Object_ID
WHERE dMeasurementGrouping.Stereotype='dMeasurementIndicator'
AND  dMeasurementIndicator.Stereotype='dMeasurementGrouping'
AND connector.Stereotype='aggregates KPI'