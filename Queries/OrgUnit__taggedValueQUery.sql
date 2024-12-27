SELECT OrgUnit.Object_ID, OrgUnit.ea_guid AS CLASSGUID , OrgUnit.Object_Type AS CLASSTYPE, OrgUnit.Name as OrgUnit, HeadCount.value AS 'HeadCount', ID.value AS 'ID'
FROM t_object as OrgUnit
INNER JOIN t_objectproperties AS HeadCount  ON (HeadCount.Object_ID =OrgUnit.Object_ID AND HeadCount.Property = ('HeadCount'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =OrgUnit.Object_ID AND ID.Property = ('ID'))
 WHERE OrgUnit.stereotype= 'dOrganizationUnit'