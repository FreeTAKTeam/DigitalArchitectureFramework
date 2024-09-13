SELECT SecurityGroup.Object_ID, SecurityGroup.ea_guid AS CLASSGUID , SecurityGroup.Object_Type AS CLASSTYPE, SecurityGroup.Name as SecurityGroup
FROM t_object as SecurityGroup
 WHERE SecurityGroup.stereotype= 'dSecurityGroup'