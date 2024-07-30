SELECT Product.Object_ID, Product.ea_guid AS CLASSGUID , Product.Object_Type AS CLASSTYPE, Product.Name as Product, ID.value, Owner.value, Source.value, RetireDate.value, Price.value
FROM t_object as Product
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Product.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =Product.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =Product.Object_ID AND Source.Property = ('Source'))
INNER JOIN t_objectproperties AS RetireDate  ON (RetireDate.Object_ID =Product.Object_ID AND RetireDate.Property = ('RetireDate'))
INNER JOIN t_objectproperties AS Price  ON (Price.Object_ID =Product.Object_ID AND Price.Property = ('Price'))
 WHERE Product.stereotype= 'dProduct'