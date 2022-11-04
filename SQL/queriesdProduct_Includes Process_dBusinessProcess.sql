-- Generated 10/24/2022 2:15:32 PM
--  dProduct (GroupName) connected with  dBusinessProcess (series)
SELECT dProduct.Name as dProduct,  dBusinessProcess.Name as  dBusinessProcess
FROM t_object AS dProduct
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dBusinessProcess.Object_ID
WHERE dProduct.Stereotype='dBusinessProcess'
AND  dBusinessProcess.Stereotype='dProduct'
AND connector.Stereotype='Includes Process'