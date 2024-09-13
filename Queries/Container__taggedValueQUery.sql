SELECT Container.Object_ID, Container.ea_guid AS CLASSGUID , Container.Object_Type AS CLASSTYPE, Container.Name as Container
FROM t_object as Container
 WHERE Container.stereotype= 'dContainer'