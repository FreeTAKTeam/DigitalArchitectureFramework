SELECT UserStory.Object_ID, UserStory.ea_guid AS CLASSGUID , UserStory.Object_Type AS CLASSTYPE, UserStory.Name as UserStory, TestScenario.value AS 'TestScenario', EstimatedEffort.value AS 'EstimatedEffort', StoryDetails.value AS 'StoryDetails'
FROM t_object as UserStory
INNER JOIN t_objectproperties AS TestScenario  ON (TestScenario.Object_ID =UserStory.Object_ID AND TestScenario.Property = ('TestScenario'))
INNER JOIN t_objectproperties AS EstimatedEffort  ON (EstimatedEffort.Object_ID =UserStory.Object_ID AND EstimatedEffort.Property = ('EstimatedEffort'))
INNER JOIN t_objectproperties AS StoryDetails  ON (StoryDetails.Object_ID =UserStory.Object_ID AND StoryDetails.Property = ('StoryDetails'))
 WHERE UserStory.stereotype= 'dUserStory'