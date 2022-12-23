-- Generated 2022-12-20 12:21:52 PM
--  dModelClass (GroupName) connected with  dTable (series)
SELECT dModelClass.Name as dModelClass,  dTable.Name as  dTable
FROM t_object AS dModelClass
INNER JOIN t_connector as connector ON dModelClass.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dTable ON connector.End_Object_ID =  dTable.Object_ID
WHERE dModelClass.Stereotype='dTable'
AND  dTable.Stereotype='dModelClass'
AND connector.Stereotype='ProvidesPersistenceFor'