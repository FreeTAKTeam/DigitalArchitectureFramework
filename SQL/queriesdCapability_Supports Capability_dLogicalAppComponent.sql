-- Generated 10/24/2022 2:12:34 PM
--  dCapability (GroupName) connected with  dLogicalAppComponent (series)
SELECT dCapability.Name as dCapability,  dLogicalAppComponent.Name as  dLogicalAppComponent
FROM t_object AS dCapability
INNER JOIN t_connector as connector ON source.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS target ON connector.End_Object_ID =  dLogicalAppComponent.Object_ID
WHERE dCapability.Stereotype='dLogicalAppComponent'
AND  dLogicalAppComponent.Stereotype='dCapability'
AND connector.Stereotype='Supports Capability'