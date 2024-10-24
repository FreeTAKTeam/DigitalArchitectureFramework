-- Generated 2024-09-16 2:13:15 PM
--  dRole (GroupName) connected with  dOrganizationUnit (series)
SELECT dRole.Name as dRole,  dOrganizationUnit.Name as  dOrganizationUnit
FROM t_object AS dOrganizationUnit
INNER JOIN t_connector as connector ON dOrganizationUnit.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRole ON connector.End_Object_ID =  dRole.Object_ID
WHERE dRole.Stereotype='dRole'
AND  dOrganizationUnit.Stereotype='dOrganizationUnit'
AND connector.Stereotype='is Associated To'