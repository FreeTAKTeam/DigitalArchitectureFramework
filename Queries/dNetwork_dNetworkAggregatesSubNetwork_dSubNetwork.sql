-- Generated 2024-12-05 10:48:01 AM
--  dNetwork (GroupName) connected with  dSubNetwork (series)
SELECT dNetwork.Name as dNetwork,  dSubNetwork.Name as  dSubNetwork
FROM t_object AS dSubNetwork
INNER JOIN t_connector as connector ON dSubNetwork.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dNetwork ON connector.End_Object_ID =  dNetwork.Object_ID
WHERE dNetwork.Stereotype='dNetwork'
AND  dSubNetwork.Stereotype='dSubNetwork'
AND connector.Stereotype='dNetworkAggregatesSubNetwork'