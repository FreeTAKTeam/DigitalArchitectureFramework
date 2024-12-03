-- Generated 2024-12-03 2:38:28 PM
--  dRequirement (GroupName) connected with  dRequirement (series)
SELECT dRequirement.Name as dRequirement,  dRequirement.Name as  dRequirement
FROM t_object AS dRequirement
INNER JOIN t_connector as connector ON dRequirement.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRequirement ON connector.End_Object_ID =  dRequirement.Object_ID
WHERE dRequirement.Stereotype='dRequirement'
AND  dRequirement.Stereotype='dRequirement'
AND connector.Stereotype='Contains Requirement'