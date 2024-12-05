SELECT DataEntity.Object_ID, DataEntity.ea_guid AS CLASSGUID , DataEntity.Object_Type AS CLASSTYPE, DataEntity.Name as DataEntity, PrivacyClassification.value AS PrivacyClassification, RetentionClassification.value AS RetentionClassification, Category.value AS Category, ID.value AS ID, Owner.value AS Owner, Source.value AS Source, isAccessible.value AS isAccessible, isTimely.value AS isTimely, isAccurate.value AS isAccurate
FROM t_object as DataEntity
INNER JOIN t_objectproperties AS PrivacyClassification  ON (PrivacyClassification.Object_ID =DataEntity.Object_ID AND PrivacyClassification.Property = ('PrivacyClassification'))
INNER JOIN t_objectproperties AS RetentionClassification  ON (RetentionClassification.Object_ID =DataEntity.Object_ID AND RetentionClassification.Property = ('RetentionClassification'))
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =DataEntity.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =DataEntity.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =DataEntity.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =DataEntity.Object_ID AND Source.Property = ('Source'))
INNER JOIN t_objectproperties AS isAccessible  ON (isAccessible.Object_ID =DataEntity.Object_ID AND isAccessible.Property = ('isAccessible'))
INNER JOIN t_objectproperties AS isTimely  ON (isTimely.Object_ID =DataEntity.Object_ID AND isTimely.Property = ('isTimely'))
INNER JOIN t_objectproperties AS isAccurate  ON (isAccurate.Object_ID =DataEntity.Object_ID AND isAccurate.Property = ('isAccurate'))
 WHERE DataEntity.stereotype= 'dDataEntity'