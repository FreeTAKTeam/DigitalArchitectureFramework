-- Generated 2022-12-20 12:21:05 PM
--  dIssue (GroupName) connected with  dRisk (series)
SELECT dIssue.Name as dIssue,  dRisk.Name as  dRisk
FROM t_object AS dIssue
INNER JOIN t_connector as connector ON dIssue.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRisk ON connector.End_Object_ID =  dRisk.Object_ID
WHERE dIssue.Stereotype='dRisk'
AND  dRisk.Stereotype='dIssue'
AND connector.Stereotype='realized by Issue'