-- Generated 2024-12-05 10:59:41 AM
--  dValueStream (GroupName) connected with  dCapability (series)
SELECT dValueStream.Name as dValueStream,  dCapability.Name as  dCapability
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON dCapability.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dValueStream ON connector.End_Object_ID =  dValueStream.Object_ID
WHERE dValueStream.Stereotype='dValueStream'
AND  dCapability.Stereotype='dCapability'
AND connector.Stereotype='dValueStreamEnablesCapability'