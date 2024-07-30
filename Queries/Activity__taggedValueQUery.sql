SELECT Activity.Object_ID, Activity.ea_guid AS CLASSGUID , Activity.Object_Type AS CLASSTYPE, Activity.Name as Activity
FROM t_object as Activity
 WHERE Activity.stereotype= 'dActivity'