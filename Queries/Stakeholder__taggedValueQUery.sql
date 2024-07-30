SELECT Stakeholder.Object_ID, Stakeholder.ea_guid AS CLASSGUID , Stakeholder.Object_Type AS CLASSTYPE, Stakeholder.Name as Stakeholder, Legitimacy.value, Power.value, role.value, Urgency.value
FROM t_object as Stakeholder
INNER JOIN t_objectproperties AS Legitimacy  ON (Legitimacy.Object_ID =Stakeholder.Object_ID AND Legitimacy.Property = ('Legitimacy'))
INNER JOIN t_objectproperties AS Power  ON (Power.Object_ID =Stakeholder.Object_ID AND Power.Property = ('Power'))
INNER JOIN t_objectproperties AS role  ON (role.Object_ID =Stakeholder.Object_ID AND role.Property = ('role'))
INNER JOIN t_objectproperties AS Urgency  ON (Urgency.Object_ID =Stakeholder.Object_ID AND Urgency.Property = ('Urgency'))
 WHERE Stakeholder.stereotype= 'dStakeholder'