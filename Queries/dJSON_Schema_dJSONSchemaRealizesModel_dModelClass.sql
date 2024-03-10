-- Generated 2024-02-28 10:53:38 AM
--  dJSON_Schema (GroupName) connected with  dModelClass (series)
SELECT dJSON_Schema.Name as dJSON_Schema,  dModelClass.Name as  dModelClass
FROM t_object AS dModelClass
INNER JOIN t_connector as connector ON dModelClass.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dJSON_Schema ON connector.End_Object_ID =  dJSON_Schema.Object_ID
WHERE dJSON_Schema.Stereotype='dJSON_Schema'
AND  dModelClass.Stereotype='dModelClass'
AND connector.Stereotype='dJSONSchemaRealizesModel'