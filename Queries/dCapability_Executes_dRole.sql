-- Generated 2022-12-20 12:19:13 PM
--  dCapability (GroupName) connected with  dRole (series)
SELECT dCapability.Name as dCapability,  dRole.Name as  dRole
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON dCapability.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRole ON connector.End_Object_ID =  dRole.Object_ID
WHERE dCapability.Stereotype='dRole'
AND  dRole.Stereotype='dCapability'
AND connector.Stereotype='Executes'