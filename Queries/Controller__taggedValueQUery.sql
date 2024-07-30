SELECT Controller.Object_ID, Controller.ea_guid AS CLASSGUID , Controller.Object_Type AS CLASSTYPE, Controller.Name as Controller
FROM t_object as Controller
 WHERE Controller.stereotype= 'dController'