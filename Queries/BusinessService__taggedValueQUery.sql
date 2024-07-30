SELECT BusinessService.Object_ID, BusinessService.ea_guid AS CLASSGUID , BusinessService.Object_Type AS CLASSTYPE, BusinessService.Name as BusinessService, Category.value, ID.value, LastStandardReviewDate.value, NextStandardReviewDate.value, Owner.value, RetireDate.value, Source.value
FROM t_object as BusinessService
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =BusinessService.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =BusinessService.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS LastStandardReviewDate  ON (LastStandardReviewDate.Object_ID =BusinessService.Object_ID AND LastStandardReviewDate.Property = ('LastStandardReviewDate'))
INNER JOIN t_objectproperties AS NextStandardReviewDate  ON (NextStandardReviewDate.Object_ID =BusinessService.Object_ID AND NextStandardReviewDate.Property = ('NextStandardReviewDate'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =BusinessService.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS RetireDate  ON (RetireDate.Object_ID =BusinessService.Object_ID AND RetireDate.Property = ('RetireDate'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =BusinessService.Object_ID AND Source.Property = ('Source'))
 WHERE BusinessService.stereotype= 'dBusinessService'