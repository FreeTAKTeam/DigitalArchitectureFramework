-- Generated 10/24/2022 2:12:26 PM
--  dCapability (GroupName) connected with  dMeasurementIndicator (series)
SELECT dCapability.Name as dCapability,  dMeasurementIndicator.Name as  dMeasurementIndicator
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dMeasurementIndicator.Object_ID
WHERE dCapability.Stereotype='dMeasurementIndicator'
AND  dMeasurementIndicator.Stereotype='dCapability'
AND connector.Stereotype='isMeasuredBy'