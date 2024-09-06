-- Generated 2024-09-06 11:30:02 AM
--  dCapability (GroupName) connected with  dLogicalAppComponent (series)
SELECT dCapability.Name as dCapability,  dLogicalAppComponent.Name as  dLogicalAppComponent
FROM t_object AS dLogicalAppComponent
INNER JOIN t_connector as connector ON dLogicalAppComponent.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dCapability ON connector.End_Object_ID =  dCapability.Object_ID
WHERE dCapability.Stereotype='dCapability'
AND  dLogicalAppComponent.Stereotype='dLogicalAppComponent'
AND connector.Stereotype='Supports Capability'