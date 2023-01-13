SELECT o1.ea_guid AS ItemGuid                                                      
 FROM ((((((t_object as o1                                                         
 INNER JOIN t_Package p ON p.Package_ID = o1.Package_ID)                           
 LEFT JOIN t_Package Package_p1 ON Package_p1.Package_id = p.parent_id)            
 LEFT JOIN t_Package Package_p2 ON Package_p2.Package_id = Package_p1.parent_id)   
 LEFT JOIN t_Package Package_p3 ON Package_p3.Package_id = Package_p2.parent_id)   
 LEFT JOIN t_Package Package_p4 ON Package_p4.Package_id = Package_p3.parent_id)   
 LEFT JOIN t_Package Package_p5 ON Package_p5.Package_id = Package_p4.parent_id)   
                                                                                   
 where o1.stereotype = 'dLogicalAppComponent' 									