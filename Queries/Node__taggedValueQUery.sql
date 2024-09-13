SELECT Node.Object_ID, Node.ea_guid AS CLASSGUID , Node.Object_Type AS CLASSTYPE, Node.Name as Node, IP.value, PublicIP.value, CPU.value, RAM.value, Owner.value, ArchitectureType.value, Disk.value, hostname.value, OS.value
FROM t_object as Node
INNER JOIN t_objectproperties AS IP  ON (IP.Object_ID =Node.Object_ID AND IP.Property = ('IP'))
INNER JOIN t_objectproperties AS PublicIP  ON (PublicIP.Object_ID =Node.Object_ID AND PublicIP.Property = ('PublicIP'))
INNER JOIN t_objectproperties AS CPU  ON (CPU.Object_ID =Node.Object_ID AND CPU.Property = ('CPU'))
INNER JOIN t_objectproperties AS RAM  ON (RAM.Object_ID =Node.Object_ID AND RAM.Property = ('RAM'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =Node.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS ArchitectureType  ON (ArchitectureType.Object_ID =Node.Object_ID AND ArchitectureType.Property = ('ArchitectureType'))
INNER JOIN t_objectproperties AS Disk  ON (Disk.Object_ID =Node.Object_ID AND Disk.Property = ('Disk'))
INNER JOIN t_objectproperties AS hostname  ON (hostname.Object_ID =Node.Object_ID AND hostname.Property = ('hostname'))
INNER JOIN t_objectproperties AS OS  ON (OS.Object_ID =Node.Object_ID AND OS.Property = ('OS'))
 WHERE Node.stereotype= 'dDeploymentNode'