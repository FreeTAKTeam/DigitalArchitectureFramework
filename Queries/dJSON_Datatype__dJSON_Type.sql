-- Generated 2024-07-24 3:44:13 PM
--  dJSON_Datatype (GroupName) connected with  dJSON_Type (series)
SELECT dJSON_Datatype.Name as dJSON_Datatype,  dJSON_Type.Name as  dJSON_Type
FROM t_object AS dJSON_Type
INNER JOIN t_connector as connector ON dJSON_Type.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dJSON_Datatype ON connector.End_Object_ID =  dJSON_Datatype.Object_ID
WHERE dJSON_Datatype.Stereotype='dJSON_Datatype'
AND  dJSON_Type.Stereotype='dJSON_Type'
AND connector.Stereotype=''