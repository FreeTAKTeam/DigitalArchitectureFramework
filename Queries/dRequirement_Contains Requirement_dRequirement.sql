-- Generated 2024-12-05 10:54:02 AM
--  dRequirement (GroupName) connected with  dRequirement (series)
SELECT dRequirement.Name as dRequirement,  dRequirement.Name as  dRequirement
FROM t_object AS dRequirement
INNER JOIN t_connector as connector ON dRequirement.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRequirement ON connector.End_Object_ID =  dRequirement.Object_ID
WHERE dRequirement.Stereotype='dRequirement'
AND  dRequirement.Stereotype='dRequirement'
AND connector.Stereotype='Contains Requirement'