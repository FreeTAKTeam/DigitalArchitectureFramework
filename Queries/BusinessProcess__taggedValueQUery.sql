SELECT BusinessProcess.Object_ID, BusinessProcess.ea_guid AS CLASSGUID , BusinessProcess.Object_Type AS CLASSTYPE, BusinessProcess.Name as BusinessProcess, Category.value, ID.value, LastStandardReviewDate.value, NextStandardReviewDate.value, Owner.value, ProcessCriticality.value, ProcessType.value, ProcessVolumetrics.value, RetireDate.value, Source.value, StandardCreationDate.value, isDocumented.value, isEffective.value, isOptimized.value, isAdopted.value
FROM t_object as BusinessProcess
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =BusinessProcess.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =BusinessProcess.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS LastStandardReviewDate  ON (LastStandardReviewDate.Object_ID =BusinessProcess.Object_ID AND LastStandardReviewDate.Property = ('LastStandardReviewDate'))
INNER JOIN t_objectproperties AS NextStandardReviewDate  ON (NextStandardReviewDate.Object_ID =BusinessProcess.Object_ID AND NextStandardReviewDate.Property = ('NextStandardReviewDate'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =BusinessProcess.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS ProcessCriticality  ON (ProcessCriticality.Object_ID =BusinessProcess.Object_ID AND ProcessCriticality.Property = ('ProcessCriticality'))
INNER JOIN t_objectproperties AS ProcessType  ON (ProcessType.Object_ID =BusinessProcess.Object_ID AND ProcessType.Property = ('ProcessType'))
INNER JOIN t_objectproperties AS ProcessVolumetrics  ON (ProcessVolumetrics.Object_ID =BusinessProcess.Object_ID AND ProcessVolumetrics.Property = ('ProcessVolumetrics'))
INNER JOIN t_objectproperties AS RetireDate  ON (RetireDate.Object_ID =BusinessProcess.Object_ID AND RetireDate.Property = ('RetireDate'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =BusinessProcess.Object_ID AND Source.Property = ('Source'))
INNER JOIN t_objectproperties AS StandardCreationDate  ON (StandardCreationDate.Object_ID =BusinessProcess.Object_ID AND StandardCreationDate.Property = ('StandardCreationDate'))
INNER JOIN t_objectproperties AS isDocumented  ON (isDocumented.Object_ID =BusinessProcess.Object_ID AND isDocumented.Property = ('isDocumented'))
INNER JOIN t_objectproperties AS isEffective  ON (isEffective.Object_ID =BusinessProcess.Object_ID AND isEffective.Property = ('isEffective'))
INNER JOIN t_objectproperties AS isOptimized  ON (isOptimized.Object_ID =BusinessProcess.Object_ID AND isOptimized.Property = ('isOptimized'))
INNER JOIN t_objectproperties AS isAdopted  ON (isAdopted.Object_ID =BusinessProcess.Object_ID AND isAdopted.Property = ('isAdopted'))
 WHERE BusinessProcess.stereotype= 'dBusinessProcess'