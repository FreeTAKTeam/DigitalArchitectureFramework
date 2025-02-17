-- Generated 2025-01-15 3:34:05 PM
--  dCapability (GroupName) connected with  dMeasurementIndicator (series)
SELECT dCapability.Name as dCapability,  dMeasurementIndicator.Name as  dMeasurementIndicator
FROM t_object AS dMeasurementIndicator
INNER JOIN t_connector as connector ON dMeasurementIndicator.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCapability ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dCapability.Stereotype='dCapability'
AND  dMeasurementIndicator.Stereotype='dMeasurementIndicator'
AND connector.Stereotype='dCapabilityisMeasuredByKPI'