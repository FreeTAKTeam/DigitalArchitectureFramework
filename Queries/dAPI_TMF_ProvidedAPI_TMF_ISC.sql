-- Generated 2024-09-16 1:51:09 PM
--  dAPI (GroupName) connected with  TMF_ISC (series)
SELECT dAPI.Name as dAPI,  TMF_ISC.Name as  TMF_ISC
FROM t_object AS TMF_ISC
INNER JOIN t_connector as connector ON TMF_ISC.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dAPI ON connector.End_Object_ID =  dAPI.Object_ID
WHERE dAPI.Stereotype='dAPI'
AND  TMF_ISC.Stereotype='TMF_ISC'
AND connector.Stereotype='TMF_ProvidedAPI'