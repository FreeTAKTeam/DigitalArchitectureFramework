-- Generated 2025-01-15 3:37:06 PM
--  dMeasurementGrouping (GroupName) connected with  dMeasurementIndicator (series)
SELECT dMeasurementGrouping.Name as dMeasurementGrouping,  dMeasurementIndicator.Name as  dMeasurementIndicator
FROM t_object AS dMeasurementIndicator
INNER JOIN t_connector as connector ON dMeasurementIndicator.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dMeasurementGrouping ON connector.End_Object_ID =  dMeasurementGrouping.Object_ID
WHERE dMeasurementGrouping.Stereotype='dMeasurementGrouping'
AND  dMeasurementIndicator.Stereotype='dMeasurementIndicator'
AND connector.Stereotype='dGroupAggregatesKPI'