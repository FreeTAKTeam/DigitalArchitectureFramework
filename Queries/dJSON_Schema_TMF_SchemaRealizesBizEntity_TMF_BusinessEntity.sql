-- Generated 2024-02-28 10:23:07 AM
--  dJSON_Schema (GroupName) connected with  TMF_BusinessEntity (series)
SELECT dJSON_Schema.Name as dJSON_Schema,  TMF_BusinessEntity.Name as  TMF_BusinessEntity
FROM t_object AS TMF_BusinessEntity
INNER JOIN t_connector as connector ON TMF_BusinessEntity.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dJSON_Schema ON connector.End_Object_ID =  dJSON_Schema.Object_ID
WHERE dJSON_Schema.Stereotype='dJSON_Schema'
AND  TMF_BusinessEntity.Stereotype='TMF_BusinessEntity'
AND connector.Stereotype='TMF_SchemaRealizesBizEntity'