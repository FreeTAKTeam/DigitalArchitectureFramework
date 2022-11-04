-- Generated 10/24/2022 2:14:33 PM
--  dModelClass (GroupName) connected with  dTable (series)
SELECT dModelClass.Name as dModelClass,  dTable.Name as  dTable
FROM t_object AS dModelClass
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dTable.Object_ID
WHERE dModelClass.Stereotype='dTable'
AND  dTable.Stereotype='dModelClass'
AND connector.Stereotype='ProvidesPersistenceFor'