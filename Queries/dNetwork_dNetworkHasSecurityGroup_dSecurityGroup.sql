-- Generated 2024-12-31 1:04:20 PM
--  dNetwork (GroupName) connected with  dSecurityGroup (series)
SELECT dNetwork.Name as dNetwork,  dSecurityGroup.Name as  dSecurityGroup
FROM t_object AS dSecurityGroup
INNER JOIN t_connector as connector ON dSecurityGroup.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dNetwork ON connector.End_Object_ID =  dNetwork.Object_ID
WHERE dNetwork.Stereotype='dNetwork'
AND  dSecurityGroup.Stereotype='dSecurityGroup'
AND connector.Stereotype='dNetworkHasSecurityGroup'