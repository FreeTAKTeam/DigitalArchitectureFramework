SELECT Logical App Component.Object_ID, Logical App Component.ea_guid AS CLASSGUID , Logical App Component.Object_Type AS CLASSTYPE, Logical App Component.Name as Logical App Component
FROM t_object as Logical App Component
 WHERE Logical App Component.stereotype= 'dLogicalAppComponent'