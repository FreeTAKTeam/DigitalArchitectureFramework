-- Generated 2024-12-31 1:01:13 PM
--  dDecision (GroupName) connected with  dInitiative (series)
SELECT dDecision.Name as dDecision,  dInitiative.Name as  dInitiative
FROM t_object AS dInitiative
INNER JOIN t_connector as connector ON dInitiative.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDecision ON connector.End_Object_ID =  dDecision.Object_ID
WHERE dDecision.Stereotype='dDecision'
AND  dInitiative.Stereotype='dInitiative'
AND connector.Stereotype='dInitiativeisMakingUseOfDecision'