-- Generated 2022-12-20 12:24:00 PM
--  dRole (GroupName) connected with  dOrganizationUnit (series)
SELECT dRole.Name as dRole,  dOrganizationUnit.Name as  dOrganizationUnit
FROM t_object AS dRole
INNER JOIN t_connector as connector ON dRole.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dOrganizationUnit ON connector.End_Object_ID =  dOrganizationUnit.Object_ID
WHERE dRole.Stereotype='dOrganizationUnit'
AND  dOrganizationUnit.Stereotype='dRole'
AND connector.Stereotype='is Associated To'