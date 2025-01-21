-- Generated 2024-12-30 3:53:46 PM
SELECT o.name AS ItemName,  o.ea_guid AS CLASSGUID  , o.Object_Type  AS [CLASSTYPE]            
 FROM t_object AS o                                                                            
 WHERE o.StereoType = 'dProgram'                                               
 AND o.ea_guid not  in                                                                         
 (                                                                                             
 	Select  o1.ea_guid                                                                          
 	from t_object as o1                                                                         
 	Inner join t_connector c on                                                                 
 							(o1.Object_ID = c.Start_Object_ID AND                               
 								c.Stereotype = 'dProgramIsPrganizedInPackages'   		                
 								)                                                               
 	inner join t_object o2 on (c.End_object_ID = o2.Object_ID 	AND o2.Stereotype = 'dGrowthPackage')   
 	WHERE o1.Stereotype = 'dProgram'	                                        
 )                                                                                             