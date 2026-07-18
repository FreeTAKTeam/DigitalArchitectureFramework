SELECT o.Name AS ItemName
, 'object' as ItemType
, o.ea_guid AS ItemGuid
, o.Object_Type AS ElementType
, o.StereoType AS ElementStereotype
, p.Name AS PackageName
, package_p1.Name AS PackageParentLevel1
, package_p2.Name AS PackageParentLevel2 
, package_p3.Name AS PackageParentLevel3
, package_p4.Name AS PackageParentLevel4
, package_p5.Name AS PackageParentLevel5
FROM ((((((t_object o
INNER JOIN t_package p ON p.Package_ID = o.Package_ID)
LEFT JOIN t_package package_p1 ON package_p1.package_ID = p.Parent_ID)
LEFT JOIN t_package package_p2 ON package_p2.package_ID = package_p1.Parent_ID)
LEFT JOIN t_package package_p3 ON package_p3.package_ID = package_p2.Parent_ID)
LEFT JOIN t_package package_p4 on package_p4.package_ID = package_p3.Parent_ID)
LEFT JOIN t_package package_p5 on package_p5.package_ID = package_p4.Parent_ID)
WHERE o.ea_guid in (#ElementGuids#)
AND o.ea_guid not in (

	Select  o1.ea_guid
	from t_object as o1
	Where o1.Status = 'Proposed'
)
