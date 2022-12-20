-- Generated 2022-12-20 12:20:09 PM
--  dDecision (GroupName) connected with  dPrinciple (series)
SELECT dDecision.Name as dDecision,  dPrinciple.Name as  dPrinciple
FROM t_object AS dDecision
INNER JOIN t_connector as connector ON dDecision.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dPrinciple ON connector.End_Object_ID =  dPrinciple.Object_ID
WHERE dDecision.Stereotype='dPrinciple'
AND  dPrinciple.Stereotype='dDecision'
AND connector.Stereotype='refers To'