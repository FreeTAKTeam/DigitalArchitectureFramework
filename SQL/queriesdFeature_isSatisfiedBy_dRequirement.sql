-- Generated 10/24/2022 2:13:28 PM
--  dFeature (GroupName) connected with  dRequirement (series)
SELECT dFeature.Name as dFeature,  dRequirement.Name as  dRequirement
FROM t_object AS dFeature
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dRequirement.Object_ID
WHERE dFeature.Stereotype='dRequirement'
AND  dRequirement.Stereotype='dFeature'
AND connector.Stereotype='isSatisfiedBy'