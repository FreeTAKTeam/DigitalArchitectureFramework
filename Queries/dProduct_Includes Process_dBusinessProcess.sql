-- Generated 2024-09-06 11:36:08 AM
--  dProduct (GroupName) connected with  dBusinessProcess (series)
SELECT dProduct.Name as dProduct,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dBusinessProcess
INNER JOIN t_connector as connector ON dBusinessProcess.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dProduct ON connector.End_Object_ID =  dProduct.Object_ID
WHERE dProduct.Stereotype='dProduct'
AND  dBusinessProcess.Stereotype='dBusinessProcess'
AND connector.Stereotype='Includes Process'