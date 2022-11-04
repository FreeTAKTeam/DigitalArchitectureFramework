-- Generated 10/24/2022 2:13:52 PM
--  dIssue (GroupName) connected with  dRequirement (series)
SELECT dIssue.Name as dIssue,  dRequirement.Name as  dRequirement
FROM t_object AS dIssue
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dRequirement.Object_ID
WHERE dIssue.Stereotype='dRequirement'
AND  dRequirement.Stereotype='dIssue'
AND connector.Stereotype='StopTheRealizationOf'