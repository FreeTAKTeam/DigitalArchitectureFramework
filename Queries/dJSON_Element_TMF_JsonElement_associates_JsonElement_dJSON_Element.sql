-- Generated 2024-02-28 10:22:47 AM
--  dJSON_Element (GroupName) connected with  dJSON_Element (series)
SELECT dJSON_Element.Name as dJSON_Element,  dJSON_Element.Name as  dJSON_Element
FROM t_object AS dJSON_Element
INNER JOIN t_connector as connector ON dJSON_Element.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dJSON_Element ON connector.End_Object_ID =  dJSON_Element.Object_ID
WHERE dJSON_Element.Stereotype='dJSON_Element'
AND  dJSON_Element.Stereotype='dJSON_Element'
AND connector.Stereotype='TMF_JsonElement_associates_JsonElement'