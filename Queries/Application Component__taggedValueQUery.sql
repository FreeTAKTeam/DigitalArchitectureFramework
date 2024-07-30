SELECT Application Component.Object_ID, Application Component.ea_guid AS CLASSGUID , Application Component.Object_Type AS CLASSTYPE, Application Component.Name as Application Component, ID.value, Category.value, BizSatisfaction.value, ITSatisfaction.value, BizCriticality.value, Cost.value, InvestmentStrategy.value, ApplicationType.value, LastStandardReviewDate.value, NextStandardReviewDate.value, RetireDate.value, Owner.value, Port.value, Source.value
FROM t_object as Application Component
INNER JOIN t_objectproperties AS ID  ON (ID.Object_ID =Application Component.Object_ID AND ID.Property = ('ID'))
INNER JOIN t_objectproperties AS Category  ON (Category.Object_ID =Application Component.Object_ID AND Category.Property = ('Category'))
INNER JOIN t_objectproperties AS BizSatisfaction  ON (BizSatisfaction.Object_ID =Application Component.Object_ID AND BizSatisfaction.Property = ('BizSatisfaction'))
INNER JOIN t_objectproperties AS ITSatisfaction  ON (ITSatisfaction.Object_ID =Application Component.Object_ID AND ITSatisfaction.Property = ('ITSatisfaction'))
INNER JOIN t_objectproperties AS BizCriticality  ON (BizCriticality.Object_ID =Application Component.Object_ID AND BizCriticality.Property = ('BizCriticality'))
INNER JOIN t_objectproperties AS Cost  ON (Cost.Object_ID =Application Component.Object_ID AND Cost.Property = ('Cost'))
INNER JOIN t_objectproperties AS InvestmentStrategy  ON (InvestmentStrategy.Object_ID =Application Component.Object_ID AND InvestmentStrategy.Property = ('InvestmentStrategy'))
INNER JOIN t_objectproperties AS ApplicationType  ON (ApplicationType.Object_ID =Application Component.Object_ID AND ApplicationType.Property = ('ApplicationType'))
INNER JOIN t_objectproperties AS LastStandardReviewDate  ON (LastStandardReviewDate.Object_ID =Application Component.Object_ID AND LastStandardReviewDate.Property = ('LastStandardReviewDate'))
INNER JOIN t_objectproperties AS NextStandardReviewDate  ON (NextStandardReviewDate.Object_ID =Application Component.Object_ID AND NextStandardReviewDate.Property = ('NextStandardReviewDate'))
INNER JOIN t_objectproperties AS RetireDate  ON (RetireDate.Object_ID =Application Component.Object_ID AND RetireDate.Property = ('RetireDate'))
INNER JOIN t_objectproperties AS Owner  ON (Owner.Object_ID =Application Component.Object_ID AND Owner.Property = ('Owner'))
INNER JOIN t_objectproperties AS Port  ON (Port.Object_ID =Application Component.Object_ID AND Port.Property = ('Port'))
INNER JOIN t_objectproperties AS Source  ON (Source.Object_ID =Application Component.Object_ID AND Source.Property = ('Source'))
 WHERE Application Component.stereotype= 'dApplicationComponent'