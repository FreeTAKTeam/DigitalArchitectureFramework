SELECT Issue.Object_ID, Issue.ea_guid AS CLASSGUID , Issue.Object_Type AS CLASSTYPE, Issue.Name as Issue, Author.value AS Author, Responsible.value AS Responsible
FROM t_object as Issue
INNER JOIN t_objectproperties AS Author  ON (Author.Object_ID =Issue.Object_ID AND Author.Property = ('Author'))
INNER JOIN t_objectproperties AS Responsible  ON (Responsible.Object_ID =Issue.Object_ID AND Responsible.Property = ('Responsible'))
 WHERE Issue.stereotype= 'dIssue'