-- Generated 2025-01-15 3:36:06 PM
--  dJSON_Schema (GroupName) connected with  dJSON_SchemaSubSet (series)
SELECT dJSON_Schema.Name as dJSON_Schema,  dJSON_SchemaSubSet.Name as  dJSON_SchemaSubSet
FROM t_object AS dJSON_SchemaSubSet
INNER JOIN t_connector as connector ON dJSON_SchemaSubSet.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dJSON_Schema ON connector.End_Object_ID =  dJSON_Schema.Object_ID
WHERE dJSON_Schema.Stereotype='dJSON_Schema'
AND  dJSON_SchemaSubSet.Stereotype='dJSON_SchemaSubSet'
AND connector.Stereotype='dJSON_SchemaSubSetGeneralizes_JSON_Schema'