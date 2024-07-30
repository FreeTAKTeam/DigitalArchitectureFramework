SELECT ModelClass.Object_ID, ModelClass.ea_guid AS CLASSGUID , ModelClass.Object_Type AS CLASSTYPE, ModelClass.Name as ModelClass, childorder.value, displayvalue.value, initparams.value, issearchable.value, issoap.value, orderby.value, parentorder.value, pkname.value, tablename.value
FROM t_object as ModelClass
INNER JOIN t_objectproperties AS childorder  ON (childorder.Object_ID =ModelClass.Object_ID AND childorder.Property = ('child_order'))
INNER JOIN t_objectproperties AS displayvalue  ON (displayvalue.Object_ID =ModelClass.Object_ID AND displayvalue.Property = ('display_value'))
INNER JOIN t_objectproperties AS initparams  ON (initparams.Object_ID =ModelClass.Object_ID AND initparams.Property = ('initparams'))
INNER JOIN t_objectproperties AS issearchable  ON (issearchable.Object_ID =ModelClass.Object_ID AND issearchable.Property = ('is_searchable'))
INNER JOIN t_objectproperties AS issoap  ON (issoap.Object_ID =ModelClass.Object_ID AND issoap.Property = ('is_soap'))
INNER JOIN t_objectproperties AS orderby  ON (orderby.Object_ID =ModelClass.Object_ID AND orderby.Property = ('orderby'))
INNER JOIN t_objectproperties AS parentorder  ON (parentorder.Object_ID =ModelClass.Object_ID AND parentorder.Property = ('parent_order'))
INNER JOIN t_objectproperties AS pkname  ON (pkname.Object_ID =ModelClass.Object_ID AND pkname.Property = ('pk_name'))
INNER JOIN t_objectproperties AS tablename  ON (tablename.Object_ID =ModelClass.Object_ID AND tablename.Property = ('table_name'))
 WHERE ModelClass.stereotype= 'dModelClass'