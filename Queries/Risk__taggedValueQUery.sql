SELECT Risk.Object_ID, Risk.ea_guid AS CLASSGUID , Risk.Object_Type AS CLASSTYPE, Risk.Name as Risk, Likehood.value, Severity.value, RiskStrategy.value
FROM t_object as Risk
INNER JOIN t_objectproperties AS Likehood  ON (Likehood.Object_ID =Risk.Object_ID AND Likehood.Property = ('Likehood'))
INNER JOIN t_objectproperties AS Severity  ON (Severity.Object_ID =Risk.Object_ID AND Severity.Property = ('Severity'))
INNER JOIN t_objectproperties AS RiskStrategy  ON (RiskStrategy.Object_ID =Risk.Object_ID AND RiskStrategy.Property = ('RiskStrategy'))
 WHERE Risk.stereotype= 'dRisk'