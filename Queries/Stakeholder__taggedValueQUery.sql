SELECT Stakeholder.Object_ID, Stakeholder.ea_guid AS CLASSGUID , Stakeholder.Object_Type AS CLASSTYPE, Stakeholder.Name as Stakeholder, Legitimacy.value AS 'Legitimacy', Power.value AS 'Power', role.value AS 'role', Urgency.value AS 'Urgency', Attitude.value AS 'Attitude', RACI.value AS 'RACI', Knowledge.value AS 'Knowledge'
FROM t_object as Stakeholder
INNER JOIN t_objectproperties AS Legitimacy  ON (Legitimacy.Object_ID =Stakeholder.Object_ID AND Legitimacy.Property = ('Legitimacy'))
INNER JOIN t_objectproperties AS Power  ON (Power.Object_ID =Stakeholder.Object_ID AND Power.Property = ('Power'))
INNER JOIN t_objectproperties AS role  ON (role.Object_ID =Stakeholder.Object_ID AND role.Property = ('role'))
INNER JOIN t_objectproperties AS Urgency  ON (Urgency.Object_ID =Stakeholder.Object_ID AND Urgency.Property = ('Urgency'))
INNER JOIN t_objectproperties AS Attitude  ON (Attitude.Object_ID =Stakeholder.Object_ID AND Attitude.Property = ('Attitude'))
INNER JOIN t_objectproperties AS RACI  ON (RACI.Object_ID =Stakeholder.Object_ID AND RACI.Property = ('RACI'))
INNER JOIN t_objectproperties AS Knowledge  ON (Knowledge.Object_ID =Stakeholder.Object_ID AND Knowledge.Property = ('Knowledge'))
 WHERE Stakeholder.stereotype= 'dStakeholder'