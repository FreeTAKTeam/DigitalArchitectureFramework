-- Generated 2024-09-06 11:30:56 AM
SELECT o.name AS ItemName,  o.ea_guid AS CLASSGUID  , o.Object_Type  AS [CLASSTYPE]            
 FROM t_object AS o                                                                            
 WHERE o.StereoType = 'dDecision'                                               
 AND o.ea_guid not  in                                                                         
 (                                                                                             
 	Select  o1.ea_guid                                                                          
 	from t_object as o1                                                                         
 	Inner join t_connector c on                                                                 
 							(o1.Object_ID = c.Start_Object_ID AND                               
 								c.Stereotype = 'refers To'   		                
 								)                                                               
 	inner join t_object o2 on (c.End_object_ID = o2.Object_ID 	AND o2.Stereotype = 'dPrinciple')   
 	WHERE o1.Stereotype = 'dDecision'	                                        
 )                                                                                             