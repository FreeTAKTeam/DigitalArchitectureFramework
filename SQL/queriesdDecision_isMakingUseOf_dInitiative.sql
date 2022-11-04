-- Generated 10/24/2022 2:13:06 PM
--  dDecision (GroupName) connected with  dInitiative (series)
SELECT dDecision.Name as dDecision,  dInitiative.Name as  dInitiative
FROM t_object AS dDecision
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dInitiative.Object_ID
WHERE dDecision.Stereotype='dInitiative'
AND  dInitiative.Stereotype='dDecision'
AND connector.Stereotype='isMakingUseOf'