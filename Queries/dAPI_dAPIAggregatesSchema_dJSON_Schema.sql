-- Generated 2024-12-31 12:59:25 PM
--  dAPI (GroupName) connected with  dJSON_Schema (series)
SELECT dAPI.Name as dAPI,  dJSON_Schema.Name as  dJSON_Schema
FROM t_object AS dJSON_Schema
INNER JOIN t_connector as connector ON dJSON_Schema.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dAPI ON connector.End_Object_ID =  dAPI.Object_ID
WHERE dAPI.Stereotype='dAPI'
AND  dJSON_Schema.Stereotype='dJSON_Schema'
AND connector.Stereotype='dAPIAggregatesSchema'