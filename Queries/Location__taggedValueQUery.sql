SELECT Location.Object_ID, Location.ea_guid AS CLASSGUID , Location.Object_Type AS CLASSTYPE, Location.Name as Location, AreaCode.value, City.value, Country.value, EmailID.value, PhoneNumber.value, Province.value, Street.value, ID.value
FROM t_object as Location
INNER JOIN t_objectproperties AS AreaCode  ON (AreaCode.Object_ID =Location.Object_ID AND AreaCode.Property = ('AreaCode'))
INNER JOIN t_objectproperties AS City  ON (City.Object_ID =Location.Object_ID AND City.Property = ('City'))
INNER JOIN t_objectproperties AS Country  ON (Country.Object_ID =Location.Object_ID AND Country.Property = ('Country'))
INNER JOIN t_objectproperties AS EmailID  ON (EmailID.Object_ID =Location.Object_ID AND EmailID.Property = ('EmailID'))
INNER JOIN t_objectproperties AS PhoneNumber  ON (PhoneNumber.Object_ID =Location.Object_ID AND PhoneNumber.Property = ('PhoneNumber'))
INNER JOIN t_objectproperties AS Province  ON (Province.Object_ID =Location.Object_ID AND Province.Property = ('Province'))
INNER JOIN t_objectproperties AS Street  ON (Street.Object_ID =Location.Object_ID AND Street.Property = ('Street'))
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Location.Object_ID AND ID.Property = ('ID'))
 WHERE Location.stereotype= 'dLocation'