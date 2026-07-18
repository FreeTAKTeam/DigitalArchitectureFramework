SELECT COUNT (o.Object_ID) AS 'ElementCount', d.Name AS ItemName
, 'Diagram' as ItemType
, d.ea_guid AS ItemGuid
, d.Diagram_Type AS ElementType
, d.StereoType AS ElementStereotype
, p.Name AS PackageName
, package_p1.Name AS PackageParentLevel1
, package_p2.Name AS PackageParentLevel2 
, package_p3.Name AS PackageParentLevel3
, package_p4.Name AS PackageParentLevel4
, package_p5.Name AS PackageParentLevel5
FROM (((((( (t_diagramobjects o
INNER JOIN t_diagram as d on d.Diagram_ID = o.Diagram_ID)
INNER JOIN t_package p ON p.Package_ID = d.Package_ID)
LEFT JOIN t_package package_p1 ON package_p1.package_ID = p.Parent_ID)
LEFT JOIN t_package package_p2 ON package_p2.package_ID = package_p1.Parent_ID)
LEFT JOIN t_package package_p3 ON package_p3.package_ID = package_p2.Parent_ID)
LEFT JOIN t_package package_p4 on package_p4.package_ID = package_p3.Parent_ID)
LEFT JOIN t_package package_p5 on package_p5.package_ID = package_p4.Parent_ID)

GROUP BY d.EA_GUID, d.Name, d.ea_guid, d.Diagram_Type, d.Stereotype, p.Name, package_p1.Name, package_p2.Name, package_p3.Name, package_p4.Name, package_p5.Name

Having  COUNT(o.Object_ID) < 2
AND d.EA_GUID IN (#ElementGuids#)
