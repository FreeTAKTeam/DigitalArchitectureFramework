-- Generated 2022-12-20 12:23:05 PM
--  dProduct (GroupName) connected with  dBusinessProcess (series)
SELECT dProduct.Name as dProduct,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dProduct
INNER JOIN t_connector as connector ON dProduct.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dBusinessProcess ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dProduct.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dProduct'
AND connector.Stereotype='Includes Process'