-- Generated 2022-12-20 12:19:04 PM
--  dCapability (GroupName) connected with  dBusinessProcess (series)
SELECT dCapability.Name as dCapability,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON dCapability.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessProcess ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dCapability.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dCapability'
AND connector.Stereotype='Ensure the correct  Operation of'