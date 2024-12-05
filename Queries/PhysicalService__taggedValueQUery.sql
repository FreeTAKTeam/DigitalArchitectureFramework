SELECT PhysicalService.Object_ID, PhysicalService.ea_guid AS CLASSGUID , PhysicalService.Object_Type AS CLASSTYPE, PhysicalService.Name as PhysicalService, Category.value AS Category, Id.value AS Id, LastStandardReviewDate.value AS LastStandardReviewDate, NextStandardReviewDate.value AS NextStandardReviewDate, Owner.value AS Owner, RetireDate.value AS RetireDate, Source.value AS Source, port.value AS port, protocol.value AS protocol, executionmode.value AS executionmode
FROM t_object as PhysicalService
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =PhysicalService.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS Id  ON (Id.Object_ID =PhysicalService.Object_ID AND Id.Property = ('Id'))
INNER JOIN t_objectproperties AS LastStandardReviewDate  ON (LastStandardReviewDate.Object_ID =PhysicalService.Object_ID AND LastStandardReviewDate.Property = ('LastStandardReviewDate'))
INNER JOIN t_objectproperties AS NextStandardReviewDate  ON (NextStandardReviewDate.Object_ID =PhysicalService.Object_ID AND NextStandardReviewDate.Property = ('NextStandardReviewDate'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =PhysicalService.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS RetireDate  ON (RetireDate.Object_ID =PhysicalService.Object_ID AND RetireDate.Property = ('RetireDate'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =PhysicalService.Object_ID AND Source.Property = ('Source'))
INNER JOIN t_objectproperties AS port  ON (port.Object_ID =PhysicalService.Object_ID AND port.Property = ('port'))
INNER JOIN t_objectproperties AS protocol  ON (protocol.Object_ID =PhysicalService.Object_ID AND protocol.Property = ('protocol'))
INNER JOIN t_objectproperties AS executionmode  ON (executionmode.Object_ID =PhysicalService.Object_ID AND executionmode.Property = ('execution_mode'))
 WHERE PhysicalService.stereotype= 'dPhysicalService'