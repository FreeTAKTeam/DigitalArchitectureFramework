SELECT o1.ea_guid AS ItemGuid
FROM ((((((t_object as o1
INNER JOIN t_package p ON p.Package_ID = o1.Package_ID)
LEFT JOIN t_package Package_p1 ON Package_p1.Package_ID = p.Parent_ID)
LEFT JOIN t_package Package_p2 ON Package_p2.Package_ID = Package_p1.Parent_ID)
LEFT JOIN t_package Package_p3 ON Package_p3.Package_ID = Package_p2.Parent_ID)
LEFT JOIN t_package Package_p4 ON Package_p4.Package_ID = Package_p3.Parent_ID)
LEFT JOIN t_package Package_p5 ON Package_p5.Package_ID = Package_p4.Parent_ID)
where o1.Status IS NOT null
