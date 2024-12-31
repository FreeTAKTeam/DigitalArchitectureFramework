-- Generated 2024-12-31 1:05:02 PM
--  dOnPremise (GroupName) connected with  dCluster (series)
SELECT dOnPremise.Name as dOnPremise,  dCluster.Name as  dCluster
FROM t_object AS dCluster
INNER JOIN t_connector as connector ON dCluster.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dOnPremise ON connector.End_Object_ID =  dOnPremise.Object_ID
WHERE dOnPremise.Stereotype='dOnPremise'
AND  dCluster.Stereotype='dCluster'
AND connector.Stereotype='dOnPremiseGeneralizesCluster'