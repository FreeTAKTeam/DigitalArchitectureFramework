SELECT Opinion.Object_ID, Opinion.ea_guid AS CLASSGUID , Opinion.Object_Type AS CLASSTYPE, Opinion.Name as Opinion
FROM t_object as Opinion
 WHERE Opinion.stereotype= 'dOpinion'