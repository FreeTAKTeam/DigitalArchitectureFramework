-- Generated 2024-12-05 10:56:13 AM
--  dSecurityGroup (GroupName) connected with  dPhysicalService (series)
SELECT dSecurityGroup.Name as dSecurityGroup,  dPhysicalService.Name as  dPhysicalService
FROM t_object AS dPhysicalService
INNER JOIN t_connector as connector ON dPhysicalService.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dSecurityGroup ON connector.End_Object_ID =  dSecurityGroup.Object_ID
WHERE dSecurityGroup.Stereotype='dSecurityGroup'
AND  dPhysicalService.Stereotype='dPhysicalService'
AND connector.Stereotype='SecurityGroupHasPhysicalService'