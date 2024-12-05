SELECT ApplicationComponent.Object_ID, ApplicationComponent.ea_guid AS CLASSGUID , ApplicationComponent.Object_Type AS CLASSTYPE, ApplicationComponent.Name as ApplicationComponent, ID.value AS ID, Category.value AS Category, BizSatisfaction.value AS BizSatisfaction, ITSatisfaction.value AS ITSatisfaction, BizCriticality.value AS BizCriticality, Cost.value AS Cost, InvestmentStrategy.value AS InvestmentStrategy, ApplicationType.value AS ApplicationType, LastStandardReviewDate.value AS LastStandardReviewDate, NextStandardReviewDate.value AS NextStandardReviewDate, RetireDate.value AS RetireDate, Owner.value AS Owner, Port.value AS Port, Source.value AS Source
FROM t_object as ApplicationComponent
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =ApplicationComponent.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =ApplicationComponent.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS BizSatisfaction  ON (BizSatisfaction.Object_ID =ApplicationComponent.Object_ID AND BizSatisfaction.Property = ('BizSatisfaction'))
INNER JOIN t_objectproperties AS ITSatisfaction  ON (ITSatisfaction.Object_ID =ApplicationComponent.Object_ID AND ITSatisfaction.Property = ('ITSatisfaction'))
INNER JOIN t_objectproperties AS BizCriticality  ON (BizCriticality.Object_ID =ApplicationComponent.Object_ID AND BizCriticality.Property = ('BizCriticality'))
INNER JOIN t_objectproperties AS Cost  ON (Cost.Object_ID =ApplicationComponent.Object_ID AND Cost.Property = ('Cost'))
INNER JOIN t_objectproperties AS InvestmentStrategy  ON (InvestmentStrategy.Object_ID =ApplicationComponent.Object_ID AND InvestmentStrategy.Property = ('InvestmentStrategy'))
INNER JOIN t_objectproperties AS ApplicationType  ON (ApplicationType.Object_ID =ApplicationComponent.Object_ID AND ApplicationType.Property = ('ApplicationType'))
INNER JOIN t_objectproperties AS LastStandardReviewDate  ON (LastStandardReviewDate.Object_ID =ApplicationComponent.Object_ID AND LastStandardReviewDate.Property = ('LastStandardReviewDate'))
INNER JOIN t_objectproperties AS NextStandardReviewDate  ON (NextStandardReviewDate.Object_ID =ApplicationComponent.Object_ID AND NextStandardReviewDate.Property = ('NextStandardReviewDate'))
INNER JOIN t_objectproperties AS RetireDate  ON (RetireDate.Object_ID =ApplicationComponent.Object_ID AND RetireDate.Property = ('RetireDate'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =ApplicationComponent.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS Port  ON (Port.Object_ID =ApplicationComponent.Object_ID AND Port.Property = ('Port'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =ApplicationComponent.Object_ID AND Source.Property = ('Source'))
 WHERE ApplicationComponent.stereotype= 'dApplicationComponent'