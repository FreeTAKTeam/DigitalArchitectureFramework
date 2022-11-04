-- Generated 10/24/2022 2:12:28 PM
--  dCapability (GroupName) connected with  dRole (series)
SELECT dCapability.Name as dCapability,  dRole.Name as  dRole
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dRole.Object_ID
WHERE dCapability.Stereotype='dRole'
AND  dRole.Stereotype='dCapability'
AND connector.Stereotype='Executes'