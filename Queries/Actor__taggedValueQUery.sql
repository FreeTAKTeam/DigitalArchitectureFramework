SELECT Actor.Object_ID, Actor.ea_guid AS CLASSGUID , Actor.Object_Type AS CLASSTYPE, Actor.Name as Actor, FTEs.value AS FTEs, ActorGoal.value AS ActorGoal, ActorType.value AS ActorType, ActorTasks.value AS ActorTasks
FROM t_object as Actor
INNER JOIN t_objectproperties AS FTEs  ON (FTEs.Object_ID =Actor.Object_ID AND FTEs.Property = ('#FTEs'))
INNER JOIN t_objectproperties AS ActorGoal  ON (ActorGoal.Object_ID =Actor.Object_ID AND ActorGoal.Property = ('ActorGoal'))
INNER JOIN t_objectproperties AS ActorType  ON (ActorType.Object_ID =Actor.Object_ID AND ActorType.Property = ('ActorType'))
INNER JOIN t_objectproperties AS ActorTasks  ON (ActorTasks.Object_ID =Actor.Object_ID AND ActorTasks.Property = ('ActorTasks'))
 WHERE Actor.stereotype= 'dActor'