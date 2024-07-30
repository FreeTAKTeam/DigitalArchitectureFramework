SELECT Program.Object_ID, Program.ea_guid AS CLASSGUID , Program.Object_Type AS CLASSTYPE, Program.Name as Program
FROM t_object as Program
 WHERE Program.stereotype= 'dProgram'