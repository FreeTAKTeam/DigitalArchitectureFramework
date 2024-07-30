SELECT Business Service.Object_ID, Business Service.ea_guid AS CLASSGUID , Business Service.Object_Type AS CLASSTYPE, Business Service.Name as Business Service, Category.value, ID.value, LastStandardReviewDate.value, NextStandardReviewDate.value, Owner.value, RetireDate.value, Source.value
FROM t_object as Business Service
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =Business Service.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Business Service.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS LastStandardReviewDate  ON (LastStandardReviewDate.Object_ID =Business Service.Object_ID AND LastStandardReviewDate.Property = ('LastStandardReviewDate'))
INNER JOIN t_objectproperties AS NextStandardReviewDate  ON (NextStandardReviewDate.Object_ID =Business Service.Object_ID AND NextStandardReviewDate.Property = ('NextStandardReviewDate'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =Business Service.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS RetireDate  ON (RetireDate.Object_ID =Business Service.Object_ID AND RetireDate.Property = ('RetireDate'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =Business Service.Object_ID AND Source.Property = ('Source'))
 WHERE Business Service.stereotype= 'dBusinessService'