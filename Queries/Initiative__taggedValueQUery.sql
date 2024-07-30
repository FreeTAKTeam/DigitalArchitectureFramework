SELECT Initiative.Object_ID, Initiative.ea_guid AS CLASSGUID , Initiative.Object_Type AS CLASSTYPE, Initiative.Name as Initiative, DetailedDescription.value, startdate.value, ImpactedCapability.value, RelatedProgram.value, startDate.value, finishDate.value, InitiativeDuration.value, kind.value, purpose.value, Rank.value, Description.value
FROM t_object as Initiative
INNER JOIN t_objectproperties AS DetailedDescription  ON (DetailedDescription.Object_ID =Initiative.Object_ID AND DetailedDescription.Property = ('DetailedDescription'))
INNER JOIN t_objectproperties AS startdate  ON (startdate.Object_ID =Initiative.Object_ID AND startdate.Property = ('startdate'))
INNER JOIN t_objectproperties AS ImpactedCapability  ON (ImpactedCapability.Object_ID =Initiative.Object_ID AND ImpactedCapability.Property = ('Impacted Capability'))
INNER JOIN t_objectproperties AS RelatedProgram  ON (RelatedProgram.Object_ID =Initiative.Object_ID AND RelatedProgram.Property = ('RelatedProgram'))
INNER JOIN t_objectproperties AS startDate  ON (startDate.Object_ID =Initiative.Object_ID AND startDate.Property = ('startDate'))
INNER JOIN t_objectproperties AS finishDate  ON (finishDate.Object_ID =Initiative.Object_ID AND finishDate.Property = ('finishDate'))
INNER JOIN t_objectproperties AS InitiativeDuration  ON (InitiativeDuration.Object_ID =Initiative.Object_ID AND InitiativeDuration.Property = ('InitiativeDuration'))
INNER JOIN t_objectproperties AS kind  ON (kind.Object_ID =Initiative.Object_ID AND kind.Property = ('kind'))
INNER JOIN t_objectproperties AS purpose  ON (purpose.Object_ID =Initiative.Object_ID AND purpose.Property = ('purpose'))
INNER JOIN t_objectproperties AS Rank  ON (Rank.Object_ID =Initiative.Object_ID AND Rank.Property = ('Rank'))
INNER JOIN t_objectproperties AS Description  ON (Description.Object_ID =Initiative.Object_ID AND Description.Property = ('Description'))
 WHERE Initiative.stereotype= 'dInitiative'