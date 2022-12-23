-- Generated 2022-12-20 12:19:09 PM
--  dCapability (GroupName) connected with  dMeasurementIndicator (series)
SELECT dCapability.Name as dCapability,  dMeasurementIndicator.Name as  dMeasurementIndicator
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON dCapability.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dMeasurementIndicator ON connector.End_Object_ID =  dMeasurementIndicator.Object_ID
WHERE dCapability.Stereotype='dMeasurementIndicator'
AND  dMeasurementIndicator.Stereotype='dCapability'
AND connector.Stereotype='isMeasuredBy'