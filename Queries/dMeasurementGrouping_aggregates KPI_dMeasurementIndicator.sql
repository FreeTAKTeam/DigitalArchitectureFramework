-- Generated 2022-12-20 12:21:35 PM
--  dMeasurementGrouping (GroupName) connected with  dMeasurementIndicator (series)
SELECT dMeasurementGrouping.Name as dMeasurementGrouping,  dMeasurementIndicator.Name as  dMeasurementIndicator
FROM t_object AS dMeasurementGrouping
INNER JOIN t_connector as connector ON dMeasurementGrouping.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dMeasurementIndicator ON connector.End_Object_ID =  dMeasurementIndicator.Object_ID
WHERE dMeasurementGrouping.Stereotype='dMeasurementIndicator'
AND  dMeasurementIndicator.Stereotype='dMeasurementGrouping'
AND connector.Stereotype='aggregates KPI'