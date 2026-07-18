SELECT d.ea_guid AS ItemGuid
FROM t_diagram d
INNER JOIN t_package p ON p.Package_ID = d.Package_ID
INNER JOIN t_object o ON o.Object_ID = d.ParentID 
    AND o.Stereotype IN ('dCapability', 'dBusinessProcess', 'dDataEntity', 'dGoal', 'dLogicalAppComponent', 'dMeasurementIndicator', 'dRole')
LEFT JOIN t_package package_p1 ON package_p1.package_ID = p.Parent_ID
LEFT JOIN t_package package_p2 ON package_p2.package_ID = package_p1.Parent_ID
LEFT JOIN t_package package_p3 ON package_p3.package_ID = package_p2.Parent_ID
LEFT JOIN t_package package_p4 ON package_p4.Package_ID = package_p3.Parent_ID
LEFT JOIN t_package package_p5 ON package_p5.Package_ID = package_p4.Parent_ID
WHERE d.Diagram_Type = 'Custom'
