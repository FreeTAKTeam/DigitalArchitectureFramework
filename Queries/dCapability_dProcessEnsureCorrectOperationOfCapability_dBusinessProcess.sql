-- Generated 2025-01-15 3:34:04 PM
--  dCapability (GroupName) connected with  dBusinessProcess (series)
SELECT dCapability.Name as dCapability,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dBusinessProcess
INNER JOIN t_connector as connector ON dBusinessProcess.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCapability ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dCapability.Stereotype='dCapability'
AND  dBusinessProcess.Stereotype='dBusinessProcess'
AND connector.Stereotype='dProcessEnsureCorrectOperationOfCapability'