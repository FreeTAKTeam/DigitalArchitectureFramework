-- Generated 2022-12-20 12:20:04 PM
--  dDecision (GroupName) connected with  dInitiative (series)
SELECT dDecision.Name as dDecision,  dInitiative.Name as  dInitiative
FROM t_object AS dDecision
INNER JOIN t_connector as connector ON dDecision.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dInitiative ON connector.End_Object_ID =  dInitiative.Object_ID
WHERE dDecision.Stereotype='dInitiative'
AND  dInitiative.Stereotype='dDecision'
AND connector.Stereotype='isMakingUseOf'