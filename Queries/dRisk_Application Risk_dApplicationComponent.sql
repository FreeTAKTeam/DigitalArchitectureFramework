-- Generated 2024-07-30 3:28:26 PM
--  dRisk (GroupName) connected with  dApplicationComponent (series)
SELECT dRisk.Name as dRisk,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON dApplicationComponent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRisk ON connector.End_Object_ID =  dRisk.Object_ID
WHERE dRisk.Stereotype='dRisk'
AND  dApplicationComponent.Stereotype='dApplicationComponent'
AND connector.Stereotype='Application Risk'