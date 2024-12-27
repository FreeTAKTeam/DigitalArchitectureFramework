-- Generated 2024-12-10 1:12:11 PM
--  dOrganizationUnit (GroupName) connected with  dStakeholder (series)
SELECT dOrganizationUnit.Name as dOrganizationUnit,  dStakeholder.Name as  dStakeholder
FROM t_object AS dStakeholder
INNER JOIN t_connector as connector ON dStakeholder.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dOrganizationUnit ON connector.End_Object_ID =  dOrganizationUnit.Object_ID
WHERE dOrganizationUnit.Stereotype='dOrganizationUnit'
AND  dStakeholder.Stereotype='dStakeholder'
AND connector.Stereotype='has Stakeholders'