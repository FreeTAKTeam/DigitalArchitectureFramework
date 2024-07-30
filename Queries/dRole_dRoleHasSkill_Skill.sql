-- Generated 2024-07-24 3:30:53 PM
--  dRole (GroupName) connected with  Skill (series)
SELECT dRole.Name as dRole,  Skill.Name as  Skill
FROM t_object AS Skill
INNER JOIN t_connector as connector ON Skill.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRole ON connector.End_Object_ID =  dRole.Object_ID
WHERE dRole.Stereotype='dRole'
AND  Skill.Stereotype='Skill'
AND connector.Stereotype='dRoleHasSkill'