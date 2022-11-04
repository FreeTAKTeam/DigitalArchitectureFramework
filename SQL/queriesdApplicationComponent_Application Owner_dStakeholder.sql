-- Generated 10/24/2022 2:11:45 PM
--  dApplicationComponent (GroupName) connected with  dStakeholder (series)
SELECT dApplicationComponent.Name as dApplicationComponent,  dStakeholder.Name as  dStakeholder
FROM t_object AS dApplicationComponent
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dStakeholder.Object_ID
WHERE dApplicationComponent.Stereotype='dStakeholder'
AND  dStakeholder.Stereotype='dApplicationComponent'
AND connector.Stereotype='Application Owner'