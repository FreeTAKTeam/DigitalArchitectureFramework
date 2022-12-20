-- Generated 2022-12-20 12:23:14 PM
--  dProgram (GroupName) connected with  dGrowthPackage (series)
SELECT dProgram.Name as dProgram,  dGrowthPackage.Name as  dGrowthPackage
FROM t_object AS dProgram
INNER JOIN t_connector as connector ON dProgram.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dGrowthPackage ON connector.End_Object_ID =  dGrowthPackage.Object_ID
WHERE dProgram.Stereotype='dGrowthPackage'
AND  dGrowthPackage.Stereotype='dProgram'
AND connector.Stereotype='is organized In'