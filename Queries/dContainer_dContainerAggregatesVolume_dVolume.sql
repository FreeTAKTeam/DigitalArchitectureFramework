-- Generated 2024-12-10 12:59:54 PM
--  dContainer (GroupName) connected with  dVolume (series)
SELECT dContainer.Name as dContainer,  dVolume.Name as  dVolume
FROM t_object AS dVolume
INNER JOIN t_connector as connector ON dVolume.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dContainer ON connector.End_Object_ID =  dContainer.Object_ID
WHERE dContainer.Stereotype='dContainer'
AND  dVolume.Stereotype='dVolume'
AND connector.Stereotype='dContainerAggregatesVolume'