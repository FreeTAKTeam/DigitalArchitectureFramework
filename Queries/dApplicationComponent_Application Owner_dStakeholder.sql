-- Generated 2024-09-06 11:28:34 AM
--  dApplicationComponent (GroupName) connected with  dStakeholder (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dStakeholder.Name as  dStakeholder
FROM t_object AS dStakeholder
INNER JOIN t_connector as connector ON dStakeholder.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dApplicationComponent ON connector.End_Object_ID =  dApplicationComponent.Object_ID
WHERE dApplicationComponent.Stereotype='dApplicationComponent'
AND  dStakeholder.Stereotype='dStakeholder'
AND connector.Stereotype='Application Owner'