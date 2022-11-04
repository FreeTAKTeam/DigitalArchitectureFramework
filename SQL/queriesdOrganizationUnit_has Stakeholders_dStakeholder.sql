-- Generated 10/24/2022 2:15:16 PM
--  dOrganizationUnit (GroupName) connected with  dStakeholder (series)
SELECT dOrganizationUnit.Name as dOrganizationUnit,  dStakeholder.Name as  dStakeholder
FROM t_object AS dOrganizationUnit
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dStakeholder.Object_ID
WHERE dOrganizationUnit.Stereotype='dStakeholder'
AND  dStakeholder.Stereotype='dOrganizationUnit'
AND connector.Stereotype='has Stakeholders'