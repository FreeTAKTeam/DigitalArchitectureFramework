-- Generated 2024-09-10 9:14:18 AM
--  dSubNetwork (GroupName) connected with  dIPRange (series)
SELECT dSubNetwork.Name as dSubNetwork,  dIPRange.Name as  dIPRange
FROM t_object AS dIPRange
INNER JOIN t_connector as connector ON dIPRange.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dSubNetwork ON connector.End_Object_ID =  dSubNetwork.Object_ID
WHERE dSubNetwork.Stereotype='dSubNetwork'
AND  dIPRange.Stereotype='dIPRange'
AND connector.Stereotype=''