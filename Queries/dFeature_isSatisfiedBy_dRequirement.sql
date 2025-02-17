-- Generated 2024-12-30 10:11:21 AM
--  dFeature (GroupName) connected with  dRequirement (series)
SELECT dFeature.Name as dFeature,  dRequirement.Name as  dRequirement
FROM t_object AS dRequirement
INNER JOIN t_connector as connector ON dRequirement.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dFeature ON connector.End_Object_ID =  dFeature.Object_ID
WHERE dFeature.Stereotype='dFeature'
AND  dRequirement.Stereotype='dRequirement'
AND connector.Stereotype='isSatisfiedBy'