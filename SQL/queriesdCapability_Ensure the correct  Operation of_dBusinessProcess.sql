-- Generated 10/24/2022 2:12:24 PM
--  dCapability (GroupName) connected with  dBusinessProcess (series)
SELECT dCapability.Name as dCapability,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dCapability.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dCapability'
AND connector.Stereotype='Ensure the correct  Operation of'