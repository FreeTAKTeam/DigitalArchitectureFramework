-- Generated 2022-12-20 12:20:42 PM
--  dGrowthPackage (GroupName) connected with  dInitiative (series)
SELECT dGrowthPackage.Name as dGrowthPackage,  dInitiative.Name as  dInitiative
FROM t_object AS dGrowthPackage
INNER JOIN t_connector as connector ON dGrowthPackage.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dInitiative ON connector.End_Object_ID =  dInitiative.Object_ID
WHERE dGrowthPackage.Stereotype='dInitiative'
AND  dInitiative.Stereotype='dGrowthPackage'
AND connector.Stereotype='is delivered by'