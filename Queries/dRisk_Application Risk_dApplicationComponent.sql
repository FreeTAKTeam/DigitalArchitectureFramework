-- Generated 2022-12-20 12:23:52 PM
--  dRisk (GroupName) connected with  dApplicationComponent (series)
SELECT dRisk.Name as dRisk,  dApplicationComponent.Name as  dApplicationComponent
FROM t_object AS dRisk
INNER JOIN t_connector as connector ON dRisk.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dRisk.Stereotype='dApplicationComponent'
AND  dApplicationComponent.Stereotype='dRisk'
AND connector.Stereotype='Application Risk'