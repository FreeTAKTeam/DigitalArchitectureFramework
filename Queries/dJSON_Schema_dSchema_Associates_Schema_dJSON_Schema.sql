-- Generated 2024-07-30 3:23:47 PM
--  dJSON_Schema (GroupName) connected with  dJSON_Schema (series)
SELECT dJSON_Schema.Name as dJSON_Schema,  dJSON_Schema.Name as  dJSON_Schema
FROM t_object AS dJSON_Schema
INNER JOIN t_connector as connector ON dJSON_Schema.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dJSON_Schema ON connector.End_Object_ID =  dJSON_Schema.Object_ID
WHERE dJSON_Schema.Stereotype='dJSON_Schema'
AND  dJSON_Schema.Stereotype='dJSON_Schema'
AND connector.Stereotype='dSchema_Associates_Schema'