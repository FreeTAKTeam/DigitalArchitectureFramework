-- Generated 2024-09-06 11:27:59 AM
--  dAPI (GroupName) connected with  dJSON_Schema (series)
SELECT dAPI.Name as dAPI,  dJSON_Schema.Name as  dJSON_Schema
FROM t_object AS dJSON_Schema
INNER JOIN t_connector as connector ON dJSON_Schema.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dAPI ON connector.End_Object_ID =  dAPI.Object_ID
WHERE dAPI.Stereotype='dAPI'
AND  dJSON_Schema.Stereotype='dJSON_Schema'
AND connector.Stereotype='dAPIAggregatesSchema'