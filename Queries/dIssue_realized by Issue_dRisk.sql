-- Generated 2024-12-30 10:11:44 AM
--  dIssue (GroupName) connected with  dRisk (series)
SELECT dIssue.Name as dIssue,  dRisk.Name as  dRisk
FROM t_object AS dRisk
INNER JOIN t_connector as connector ON dRisk.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dIssue ON connector.End_Object_ID =  dIssue.Object_ID
WHERE dIssue.Stereotype='dIssue'
AND  dRisk.Stereotype='dRisk'
AND connector.Stereotype='realized by Issue'