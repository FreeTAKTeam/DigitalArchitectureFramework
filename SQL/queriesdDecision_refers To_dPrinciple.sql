-- Generated 10/24/2022 2:13:09 PM
--  dDecision (GroupName) connected with  dPrinciple (series)
SELECT dDecision.Name as dDecision,  dPrinciple.Name as  dPrinciple
FROM t_object AS dDecision
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dPrinciple.Object_ID
WHERE dDecision.Stereotype='dPrinciple'
AND  dPrinciple.Stereotype='dDecision'
AND connector.Stereotype='refers To'