SELECT Decision.Object_ID, Decision.ea_guid AS CLASSGUID , Decision.Object_Type AS CLASSTYPE, Decision.Name as Decision, SubjectArea.value AS 'SubjectArea', Topic.value AS 'Topic', Assumptions.value AS 'Assumptions', Motivation.value AS 'Motivation', Alternatives.value AS 'Alternatives', Decision.value AS 'Decision', Justification.value AS 'Justification', Implications.value AS 'Implications', RelatedDecisions.value AS 'RelatedDecisions'
FROM t_object as Decision
INNER JOIN t_objectproperties AS SubjectArea  ON (SubjectArea.Object_ID =Decision.Object_ID AND SubjectArea.Property = ('Subject Area'))
INNER JOIN t_objectproperties AS Topic  ON (Topic.Object_ID =Decision.Object_ID AND Topic.Property = ('Topic'))
INNER JOIN t_objectproperties AS Assumptions  ON (Assumptions.Object_ID =Decision.Object_ID AND Assumptions.Property = ('Assumptions'))
INNER JOIN t_objectproperties AS Motivation  ON (Motivation.Object_ID =Decision.Object_ID AND Motivation.Property = ('Motivation'))
INNER JOIN t_objectproperties AS Alternatives  ON (Alternatives.Object_ID =Decision.Object_ID AND Alternatives.Property = ('Alternatives'))
INNER JOIN t_objectproperties AS Decision  ON (Decision.Object_ID =Decision.Object_ID AND Decision.Property = ('Decision'))
INNER JOIN t_objectproperties AS Justification  ON (Justification.Object_ID =Decision.Object_ID AND Justification.Property = ('Justification'))
INNER JOIN t_objectproperties AS Implications  ON (Implications.Object_ID =Decision.Object_ID AND Implications.Property = ('Implications'))
INNER JOIN t_objectproperties AS RelatedDecisions  ON (RelatedDecisions.Object_ID =Decision.Object_ID AND RelatedDecisions.Property = ('RelatedDecisions'))
 WHERE Decision.stereotype= 'dDecision'