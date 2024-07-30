SELECT Data Entity.Object_ID, Data Entity.ea_guid AS CLASSGUID , Data Entity.Object_Type AS CLASSTYPE, Data Entity.Name as Data Entity, PrivacyClassification.value, RetentionClassification.value, Category.value, ID.value, Owner.value, Source.value
FROM t_object as Data Entity
INNER JOIN t_objectproperties AS PrivacyClassification  ON (PrivacyClassification.Object_ID =Data Entity.Object_ID AND PrivacyClassification.Property = ('PrivacyClassification'))
INNER JOIN t_objectproperties AS RetentionClassification  ON (RetentionClassification.Object_ID =Data Entity.Object_ID AND RetentionClassification.Property = ('RetentionClassification'))
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =Data Entity.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Data Entity.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =Data Entity.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =Data Entity.Object_ID AND Source.Property = ('Source'))
 WHERE Data Entity.stereotype= 'dDataEntity'