-- Generated 2024-12-03 2:20:04 PM
--  dIssue (GroupName) connected with  dRequirement (series)
SELECT dIssue.Name as dIssue,  dRequirement.Name as  dRequirement
FROM t_object AS dRequirement
INNER JOIN t_connector as connector ON dRequirement.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dIssue ON connector.End_Object_ID =  dIssue.Object_ID
WHERE dIssue.Stereotype='dIssue'
AND  dRequirement.Stereotype='dRequirement'
AND connector.Stereotype='StopTheRealizationOf'