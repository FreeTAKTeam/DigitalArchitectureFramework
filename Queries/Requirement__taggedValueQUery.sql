SELECT Requirement.Object_ID, Requirement.ea_guid AS CLASSGUID , Requirement.Object_Type AS CLASSTYPE, Requirement.Name as Requirement, ID.value AS ID, Author.value AS Author, Status.value AS Status, Priority.value AS Priority, Proofreader.value AS Proofreader, Type.value AS Type
FROM t_object as Requirement
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Requirement.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Author  ON (Author.Object_ID =Requirement.Object_ID AND Author.Property = ('Author'))
INNER JOIN t_objectproperties AS Status  ON (Status.Object_ID =Requirement.Object_ID AND Status.Property = ('Status'))
INNER JOIN t_objectproperties AS Priority  ON (Priority.Object_ID =Requirement.Object_ID AND Priority.Property = ('Priority'))
INNER JOIN t_objectproperties AS Proofreader  ON (Proofreader.Object_ID =Requirement.Object_ID AND Proofreader.Property = ('Proofreader'))
INNER JOIN t_objectproperties AS Type  ON (Type.Object_ID =Requirement.Object_ID AND Type.Property = ('Type'))
 WHERE Requirement.stereotype= 'dRequirement'