-- Generated 2024-12-10 12:58:39 PM
--  dCapability (GroupName) connected with  dRole (series)
SELECT dCapability.Name as dCapability,  dRole.Name as  dRole
FROM t_object AS dRole
INNER JOIN t_connector as connector ON dRole.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCapability ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dCapability.Stereotype='dCapability'
AND  dRole.Stereotype='dRole'
AND connector.Stereotype='dRoleExecutesCapability'