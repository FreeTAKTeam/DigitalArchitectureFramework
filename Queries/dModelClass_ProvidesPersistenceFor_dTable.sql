-- Generated 2024-07-30 3:25:31 PM
--  dModelClass (GroupName) connected with  dTable (series)
SELECT dModelClass.Name as dModelClass,  dTable.Name as  dTable
FROM t_object AS dTable
INNER JOIN t_connector as connector ON dTable.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dModelClass ON connector.End_Object_ID =  dModelClass.Object_ID
WHERE dModelClass.Stereotype='dModelClass'
AND  dTable.Stereotype='dTable'
AND connector.Stereotype='ProvidesPersistenceFor'