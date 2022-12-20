-- Generated 2022-12-20 12:22:45 PM
--  dOrganizationUnit (GroupName) connected with  dStakeholder (series)
SELECT dOrganizationUnit.Name as dOrganizationUnit,  dStakeholder.Name as  dStakeholder
FROM t_object AS dOrganizationUnit
INNER JOIN t_connector as connector ON dOrganizationUnit.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dStakeholder ON connector.End_Object_ID =  dStakeholder.Object_ID
WHERE dOrganizationUnit.Stereotype='dStakeholder'
AND  dStakeholder.Stereotype='dOrganizationUnit'
AND connector.Stereotype='has Stakeholders'