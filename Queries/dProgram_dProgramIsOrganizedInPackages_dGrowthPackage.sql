-- Generated 2025-01-15 3:38:51 PM
--  dProgram (GroupName) connected with  dGrowthPackage (series)
SELECT dProgram.Name as dProgram,  dGrowthPackage.Name as  dGrowthPackage
FROM t_object AS dGrowthPackage
INNER JOIN t_connector as connector ON dGrowthPackage.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dProgram ON connector.End_Object_ID =  dProgram.Object_ID
WHERE dProgram.Stereotype='dProgram'
AND  dGrowthPackage.Stereotype='dGrowthPackage'
AND connector.Stereotype='dProgramIsOrganizedInPackages'