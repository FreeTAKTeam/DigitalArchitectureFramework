SELECT Table.Object_ID, Table.ea_guid AS CLASSGUID , Table.Object_Type AS CLASSTYPE, Table.Name as Table, Database.value AS Database
FROM t_object as Table
INNER JOIN t_objectproperties AS Database  ON (Database.Object_ID =Table.Object_ID AND Database.Property = ('Database'))
 WHERE Table.stereotype= 'dTable'