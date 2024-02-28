-- Generated 2024-02-28 10:47:06 AM
--  dGrowthPackage (GroupName) connected with  dInitiative (series)
SELECT dGrowthPackage.Name as dGrowthPackage,  dInitiative.Name as  dInitiative
FROM t_object AS dInitiative
INNER JOIN t_connector as connector ON dInitiative.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dGrowthPackage ON connector.End_Object_ID =  dGrowthPackage.Object_ID
WHERE dGrowthPackage.Stereotype='dGrowthPackage'
AND  dInitiative.Stereotype='dInitiative'
AND connector.Stereotype='is delivered by'