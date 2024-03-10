-- Generated 2024-02-28 10:53:34 AM
--  dJSON_Schema (GroupName) connected with  dJSON_Element (series)
SELECT dJSON_Schema.Name as dJSON_Schema,  dJSON_Element.Name as  dJSON_Element
FROM t_object AS dJSON_Element
INNER JOIN t_connector as connector ON dJSON_Element.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dJSON_Schema ON connector.End_Object_ID =  dJSON_Schema.Object_ID
WHERE dJSON_Schema.Stereotype='dJSON_Schema'
AND  dJSON_Element.Stereotype='dJSON_Element'
AND connector.Stereotype='dSchemaAssociatesElement'