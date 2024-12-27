-- Generated 2024-12-10 1:01:33 PM
--  dDecision (GroupName) connected with  dPrinciple (series)
SELECT dDecision.Name as dDecision,  dPrinciple.Name as  dPrinciple
FROM t_object AS dPrinciple
INNER JOIN t_connector as connector ON dPrinciple.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dDecision ON connector.End_Object_ID =  dDecision.Object_ID
WHERE dDecision.Stereotype='dDecision'
AND  dPrinciple.Stereotype='dPrinciple'
AND connector.Stereotype='refers To'