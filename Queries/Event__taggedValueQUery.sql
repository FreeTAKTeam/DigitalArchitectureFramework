SELECT Event.Object_ID, Event.ea_guid AS CLASSGUID , Event.Object_Type AS CLASSTYPE, Event.Name as Event, Category.value AS 'Category', ID.value AS 'ID', Owner.value AS 'Owner', Source.value AS 'Source'
FROM t_object as Event
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =Event.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Event.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =Event.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =Event.Object_ID AND Source.Property = ('Source'))
 WHERE Event.stereotype= 'dEvent'