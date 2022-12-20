-- Generated 2022-12-20 12:21:00 PM
--  dIssue (GroupName) connected with  dRequirement (series)
SELECT dIssue.Name as dIssue,  dRequirement.Name as  dRequirement
FROM t_object AS dIssue
INNER JOIN t_connector as connector ON dIssue.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRequirement ON connector.End_Object_ID =  dRequirement.Object_ID
WHERE dIssue.Stereotype='dRequirement'
AND  dRequirement.Stereotype='dIssue'
AND connector.Stereotype='StopTheRealizationOf'