SELECT o.Name AS ItemName                                      
 , 'object' as ItemType                                                            
 , o.ea_guid AS ItemGuid                                                           
 , o.Object_Type AS ElementType                                                    
 , o.StereoType AS ElementStereotype                                               
 , p.name AS PackageName                                                           
 , package_p1.name AS PackageParentLevel1                                          
 , package_p2.name AS PackageParentLevel2                                          
 , package_p3.name AS PackageParentLevel3                                          
 , package_p4.name AS PackageParentLevel4                                          
 , package_p5.name AS PackageParentLevel5                                          
 FROM ((((((t_object o                                                             
 INNER JOIN t_package p ON p.Package_ID = o.Package_ID)                            
 LEFT JOIN t_package package_p1 ON package_p1.package_id = p.parent_id)            
 LEFT JOIN t_package package_p2 ON package_p2.package_id = package_p1.parent_id)   
 LEFT JOIN t_package package_p3 ON package_p3.package_id = package_p2.parent_id)   
 LEFT JOIN t_package package_p4 on package_p4.package_id = package_p3.parent_id)   
 LEFT JOIN t_package package_p5 on package_p5.package_id = package_p4.parent_id)   
 WHERE o.ea_guid in (#ElementGuids#)                                               
 AND o.ea_guid in (                                                                
 Select o1.ea_guid from t_object as o1                                             
 where o1.Note IS NULL                                                             
 and o1.stereotype = 'dCluster' )                                      