SELECT Capability.Object_ID, Capability.ea_guid AS CLASSGUID , Capability.Object_Type AS CLASSTYPE, Capability.Name as Capability, BusinessValue.value AS 'BusinessValue', Category.value AS 'Category', ID.value AS 'ID', Owner.value AS 'Owner', Source.value AS 'Source', Increments.value AS 'Increments', IncrementsToBe.value AS 'IncrementsToBe', IncrementVertical.value AS 'IncrementVertical', IncrementSupplyChain.value AS 'IncrementSupplyChain', Cost.value AS 'Cost', Criticality.value AS 'Criticality', Risk.value AS 'Risk'
FROM t_object as Capability
INNER JOIN t_objectproperties AS BusinessValue  ON (BusinessValue.Object_ID =Capability.Object_ID AND BusinessValue.Property = ('BusinessValue'))
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =Capability.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Capability.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =Capability.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =Capability.Object_ID AND Source.Property = ('Source'))
INNER JOIN t_objectproperties AS Increments  ON (Increments.Object_ID =Capability.Object_ID AND Increments.Property = ('Increments'))
INNER JOIN t_objectproperties AS IncrementsToBe  ON (IncrementsToBe.Object_ID =Capability.Object_ID AND IncrementsToBe.Property = ('IncrementsToBe'))
INNER JOIN t_objectproperties AS IncrementVertical  ON (IncrementVertical.Object_ID =Capability.Object_ID AND IncrementVertical.Property = ('IncrementVertical'))
INNER JOIN t_objectproperties AS IncrementSupplyChain  ON (IncrementSupplyChain.Object_ID =Capability.Object_ID AND IncrementSupplyChain.Property = ('IncrementSupplyChain'))
INNER JOIN t_objectproperties AS Cost  ON (Cost.Object_ID =Capability.Object_ID AND Cost.Property = ('Cost'))
INNER JOIN t_objectproperties AS Criticality  ON (Criticality.Object_ID =Capability.Object_ID AND Criticality.Property = ('Criticality'))
INNER JOIN t_objectproperties AS Risk  ON (Risk.Object_ID =Capability.Object_ID AND Risk.Property = ('Risk'))
 WHERE Capability.stereotype= 'dCapability'