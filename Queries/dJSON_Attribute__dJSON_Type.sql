-- Generated 2024-07-24 3:44:04 PM
--  dJSON_Attribute (GroupName) connected with  dJSON_Type (series)
SELECT dJSON_Attribute.Name as dJSON_Attribute,  dJSON_Type.Name as  dJSON_Type
FROM t_object AS dJSON_Type
INNER JOIN t_connector as connector ON dJSON_Type.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dJSON_Attribute ON connector.End_Object_ID =  dJSON_Attribute.Object_ID
WHERE dJSON_Attribute.Stereotype='dJSON_Attribute'
AND  dJSON_Type.Stereotype='dJSON_Type'
AND connector.Stereotype=''