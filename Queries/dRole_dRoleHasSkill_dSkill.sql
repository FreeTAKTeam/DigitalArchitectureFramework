-- Generated 2025-01-15 3:39:58 PM
--  dRole (GroupName) connected with  dSkill (series)
SELECT dRole.Name as dRole,  dSkill.Name as  dSkill
FROM t_object AS dSkill
INNER JOIN t_connector as connector ON dSkill.Object_ID = connector.Start_Object_ID
INNER JOIN t_object AS dRole ON connector.End_Object_ID =  dRole.Object_ID
WHERE dRole.Stereotype='dRole'
AND  dSkill.Stereotype='dSkill'
AND connector.Stereotype='dRoleHasSkill'