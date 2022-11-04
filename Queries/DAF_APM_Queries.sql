-- list of querries that support APM functions with the DAF metamodel
-- 1.Cost per Capability
-- 2. Application (as GroupName) connected with another applications (as series)
-- 3.  dCapability (GroupName) connected with  dLogicalAppComponent (series)
-- 4. dCapability (GroupName) connected with  dBusinessProcess (series)
--  5. dCapability (GroupName) connected with  Role (series)
-- 6. Application by responsible Stakeholder
--7. Application by role

-- 8.  applications by Country
-- 9. applications costs, IT and Biz Satisfaction  by Capability
-- 10. Applications by ORGANIZATION
-- 11. application: Years before retirement
-- 12. Application Risk
-- 13 Application by owner

-- 1. Cost per Capability
-- MYSQL
SELECT SUM(cost_prop.Value) AS ChartValue, tam_app.Name AS Series
FROM t_object AS app
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS type_prop ON type_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS maint_prop ON maint_prop.Object_ID = app.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS tam_app ON conn.End_Object_ID = tam_app.Object_ID
WHERE app.Stereotype = 'Application'  
AND cost_prop.Property = ('Cost')
AND type_prop.Property = 'Application_Type' AND type_prop.Value IN ('Custom Application','Packaged Application','Package Customization')

AND tam_app.Stereotype = 'AcordCapability'  
GROUP BY tam_app.Name
ORDER BY SUM(cost_prop.Value) DESC
Limit 15;

-- details query
SELECT Distinct app.Name AS AppName, app.ea_guid  as classguid , app.object_type as hide_basetype, app.stereotype as hide_stereotype , cost_prop.value as Cost
FROM t_object AS app
INNER JOIN  t_objectproperties cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS maint_prop ON maint_prop.Object_ID = app.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS tam_app ON conn.End_Object_ID = tam_app.Object_ID
WHERE app.Stereotype = 'Application'  
AND tam_app.Stereotype = 'AcordCapability'  
AND tam_app.Name = 'Claims Management'
AND cost_prop.property='cost'

--- SQL server
SELECT SUM(CAST(cost_prop.Value as Int)) AS ChartValue, tam_app.Name AS Series
FROM t_object AS app
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS type_prop ON type_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS maint_prop ON maint_prop.Object_ID = app.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS tam_app ON conn.End_Object_ID = tam_app.Object_ID
WHERE app.Stereotype = ('dApplicationComponent')  
AND cost_prop.Property = ('Cost')
AND tam_app.Stereotype = ('dCapability')  
GROUP BY tam_app.name;


-- 2. Application (GroupName) connected with another applications (series)
--- Access SQL
SELECT t_object.Name as groupname, t_object_1.Name as series
FROM (t_object 
INNER JOIN t_connector ON t_object.Object_ID = t_connector.Start_Object_ID) 
INNER JOIN t_object AS t_object_1 ON t_connector.End_Object_ID = t_object_1.Object_ID
WHERE (((t_object.Stereotype)='dApplicationComponent') 
AND ((t_object_1.Stereotype)='dApplicationComponent') 
AND ((t_connector.Connector_Type)='Assembly'))


-- details query
-- TBD

-- 3. dCapability (GroupName) connected with  dLogicalAppComponent (series)
SELECT t_object.Name as groupname, t_object_1.Name as series
FROM (t_object 
INNER JOIN t_connector ON t_object.Object_ID = t_connector.Start_Object_ID) 
INNER JOIN t_object AS t_object_1 ON t_connector.End_Object_ID = t_object_1.Object_ID
WHERE (((t_object.Stereotype)='dCapability') 
AND ((t_object_1.Stereotype)='dLogicalAppComponent') 
AND ((t_connector.Connector_Type)='Aggregation'))

--  4. dCapability (GroupName) connected with  dBusinessProcess (series)
--- Access
SELECT t_object.Name as groupname, t_object_1.Name as series
FROM (t_object 
INNER JOIN t_connector ON t_object.Object_ID = t_connector.Start_Object_ID) 
INNER JOIN t_object AS t_object_1 ON t_connector.End_Object_ID = t_object_1.Object_ID
WHERE (((t_object.Stereotype)='dCapability') 
AND ((t_object_1.Stereotype)='dBusinessProcess') 
AND ((t_connector.Connector_Type)='Aggregation'))

--  5. dCapability (GroupName) connected with  Role (series)
SELECT t_object.Name as groupname, t_object_1.Name as series
FROM (t_object INNER JOIN t_connector ON t_object.Object_ID = t_connector.Start_Object_ID) 
INNER JOIN t_object AS t_object_1 ON t_connector.End_Object_ID = t_object_1.Object_ID
WHERE (((t_object.Stereotype)='dCapability') 
AND ((t_object_1.Stereotype)='dRole') 
AND ((t_connector.Connector_Type)='Aggregation'))


-- 6. Application by stakeholder
select target.Name as groupname, source.Name as  series

from ((t_object source

left join t_connector con on con.Start_Object_ID = source.Object_ID)
join t_object target on target.Object_ID = con.End_Object_ID)

where
source.Stereotype='Role'
and target.Stereotype='dApplicationComponent' 
and con.Connector_Type='Association'
and con.Stereotype="dStakeHolder"

-- 6. Application by stakeholder SQL
select target.Name as groupname, source.Name as  series
from t_object source
inner join t_connector con on con.Start_Object_ID = source.Object_ID
inner join t_object target on target.Object_ID = con.End_Object_ID
where
source.Stereotype='Role'
and target.Stereotype='dApplicationComponent' 
and con.Connector_Type='Association'
and con.Stereotype= 'dStakeHolder'


--7. Application by role
select target.Name as groupname, source.Name as  series

from ((t_object source

left join t_connector con on con.Start_Object_ID = source.Object_ID)
join t_object target on target.Object_ID = con.End_Object_ID)

where
source.Stereotype='Role'
and target.Stereotype='dApplicationComponent' 
and con.Connector_Type='Dependency'
and con.Stereotype="dRole"

-- Application by role: details query
select target.Name as Name 
from ((t_object source
left join t_connector con on con.Start_Object_ID = source.Object_ID)
join t_object target on target.Object_ID = con.End_Object_ID)
where
source.Stereotype='Role'
AND source.name='<series>'
and target.Stereotype='Application' 
and con.Connector_Type='Dependency'
and con.Stereotype="Senior Responsible"


--8. applications by Country TODO
select target.Name as groupname, source.Name as series 

from (((t_object source
INNER JOIN t_package ON t_package.Package_ID = source.Package_ID 
left join t_connector con on con.Start_Object_ID = source.Object_ID)
join t_object target on target.Object_ID = con.End_Object_ID)
left join t_objectproperties op on op.Object_ID=source.Object_ID
left join t_objectproperties op2 on op2.Object_ID=source.Object_ID
left join t_objectproperties op3 on op3.Object_ID=source.Object_ID)

where
source.Stereotype='ArchiMate_ApplicationComponent' 
and target.Stereotype='ArchiMate_Location'
and t_package.ea_guid = '{34239458-F65E-4af2-B692-BB241F65E4BF}'
and con.Stereotype='ArchiMate_Association'
AND op.Property= 'App Type'
AND op.Value LIKE'Application'
AND op2.Property= 'Import Date'
AND op2.Value LIKE'20191028'

Group by GroupName 
ORDER BY groupname ASC

--Result query
select t_object.Name  as Application, t_object.Note as 'Notes', t_object.ea_guid as classguid   from t_object 
WHERE
t_object.Stereotype='ArchiMate_ApplicationComponent'
AND  (t_object.Name = '<series>')


-- 9. applications costs, IT and Biz Satisfaction  by Capability
SELECT SUM(cost_prop.Value) AS ChartValue, SUM(BizSatisfaction_prop.Value) AS xvalue, SUM(ITSatisfaction_prop.Value) AS yvalue, Capability.Name AS Series
FROM t_object AS app
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS BizSatisfaction_prop ON BizSatisfaction_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS ITSatisfaction_prop  ON ITSatisfaction_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS type_prop  ON type_prop.Object_ID = app.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS Capability ON conn.End_Object_ID = Capability.Object_ID
WHERE app.Stereotype = ('Application')  
AND cost_prop.Property = ('Cost')
AND BizSatisfaction_prop.Property = ('BizSatisfaction')
AND ITSatisfaction_prop.Property = ('ITSatisfaction')
AND Capability.Stereotype = ('Capability')  
Group by Capability.Name
ORDER BY SUM(cost_prop.Value) DESC
Limit 15;
-- 9. applications costs, IT and Biz Satisfaction  by Capability
-- Result query
select distinct app.Name as Name, BizSatisfaction_prop.value as BizSatisfaction, ITSatisfaction_prop.value as ITSatisfaction, app.ea_guid as classguid 
FROM t_object AS app
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS BizSatisfaction_prop ON BizSatisfaction_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS ITSatisfaction_prop  ON ITSatisfaction_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS type_prop  ON type_prop.Object_ID = app.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS Capability ON conn.End_Object_ID = Capability.Object_ID

where Capability.Name = '<series>'
AND Capability.Stereotype = ('Capability')  
AND app.Stereotype  = ('Application')  
AND cost_prop.Property = ('Cost')
AND BizSatisfaction_prop.Property = ('BizSatisfaction')
AND ITSatisfaction_prop.Property = ('ITSatisfaction')


-- 10. Applications by ORGANIZATION
select target.Name as groupname, source.Name as  series

from ((t_object source

left join t_connector con on con.Start_Object_ID = source.Object_ID)
join t_object target on target.Object_ID = con.End_Object_ID)

where
source.Stereotype='Application'
and target.Stereotype='Organization' 
and con.Connector_Type='Aggregation'

-- 10. Applications by ORGANIZATION
--Result query
select distinct app.Name as Name, BizSatisfaction_prop.value as BizSatisfaction, ITSatisfaction_prop.value as ITSatisfaction,app.ea_guid as classguid 
FROM t_object AS app
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS BizSatisfaction_prop ON BizSatisfaction_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS ITSatisfaction_prop  ON ITSatisfaction_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS type_prop  ON type_prop.Object_ID = app.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS Capability ON conn.End_Object_ID = Capability.Object_ID

where Capability.Name = '<series>'
AND Capability.Stereotype = ('Organization')  
AND app.Stereotype  = ('Application')  
AND cost_prop.Property = ('Cost')
AND BizSatisfaction_prop.Property = ('BizSatisfaction')
AND ITSatisfaction_prop.Property = ('ITSatisfaction')
---------------------------------------------------------------------------------------------
-- 11. application: Years before retirement
-- test data
SELECT  app.Object_ID, app.ea_guid AS CLASSGUID , app.Object_Type AS CLASSTYPE, app.Name as App,   AppRetireDate.value  AS YearsBeforeRetirement,  
app.Package_ID as Package 
from t_object as app
left join t_objectproperties AS AppRetireDate ON AppRetireDate.Object_ID=app.Object_ID

where app.stereotype='dApplicationComponent'
AND AppRetireDate.Property = 'RetireDate'
AND app.Package_ID ='8726' 

---------------------------------------------------------------------------------------------

--works in ACCESS
SELECT  app.Object_ID, app.ea_guid AS CLASSGUID , app.Object_Type AS CLASSTYPE, app.Name as App,  DATEDIFF("yyyy",  Date(), AppRetireDate.value) AS YearsBeforeRetirement 
from t_object as app
left join t_objectproperties AS AppRetireDate ON AppRetireDate.Object_ID=app.Object_ID

where app.stereotype='dApplicationComponent'
AND AppRetireDate.Property = 'RetireDate'

-- WORKS in SQL Server
SELECT  app.Object_ID, app.ea_guid AS CLASSGUID , app.Object_Type AS CLASSTYPE, app.Name as groupname,  DATEDIFF("yyyy",  getDate(), CONVERT(datetime, AppRetireDate.value, 101)) AS  series 
from t_object as app
left join t_objectproperties AS AppRetireDate ON AppRetireDate.Object_ID=app.Object_ID

where app.stereotype='dApplicationComponent'
AND AppRetireDate.Property = 'RetireDate'
AND app.Package_ID ='8726' 

--  application: Years before retirement WORKS in SQL Server, top 10 only
SELECT TOP 10  app.Object_ID, app.ea_guid AS CLASSGUID , app.Object_Type AS CLASSTYPE, app.Name as series,  DATEDIFF("yyyy",  getDate(), CONVERT(datetime, AppRetireDate.value, 101)) AS  ChartValue
from t_object as app
left join t_objectproperties AS AppRetireDate ON AppRetireDate.Object_ID=app.Object_ID

where app.stereotype='dApplicationComponent'
AND AppRetireDate.Property = 'RetireDate'
AND app.Package_ID ='8726'
Order By ChartValue ASC

-- Works in MYSQL
--TBD
---------------------------------------------------------------------------------------------
-- function
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-- 12. Application Risk
---------------------------------------------------------------------------------------------
select target.Name as groupname, source.Name as  series

from ((t_object source

left join t_connector con on con.Start_Object_ID = source.Object_ID)
join t_object target on target.Object_ID = con.End_Object_ID)

where
source.Stereotype='dApplicationComponent'
and target.Stereotype='drisk' 
and con.Connector_Type='Aggregation'



--------------------
-- select the diagram by name. Join with the objectID in the diagramObjectTable, join with the Object properties
SELECT t_object.Name as [ElementName], t_object.Note as [ElementNote], t_object.Stereotype, t_object.Author
FROM (t_diagram 
INNER JOIN t_diagramobjects ON t_diagram.Diagram_ID = t_diagramobjects.Diagram_ID) 
INNER JOIN t_object ON t_diagramobjects.Object_ID = t_object.Object_ID
WHERE (((t_object.Stereotype)="ArchiMate_BusinessProcess")
AND (t_diagram.Diagram_ID)=116)

--------------------
SELECT
  l2_id_prop.Value AS 'l2_cap_id', l2_cap.ea_guid as 'l2_cap_guid', l2_cap.Name AS 'l2_cap_name'
FROM
  t_object AS l2_cap
  INNER JOIN
    t_package AS pl_pkg
    ON
      pl_pkg.Package_ID = l2_cap.Package_ID
  INNER JOIN
    t_objectproperties AS l2_id_prop
    ON
      l2_id_prop.Object_ID = l2_cap.Object_ID
  INNER JOIN
    t_objectproperties AS l2_lvl_prop
    ON
      l2_lvl_prop.Object_ID = l2_cap.Object_ID
 
WHERE
  pl_pkg.ea_guid           = '{9BD1E3C3-EA0A-465b-ADF8-313AC0E888F0}'
  AND l2_cap.Stereotype    = 'ArchiMate_ApplicationFunction'
  AND l2_id_prop.Property  = 'Capability ID'
  AND l2_lvl_prop.Property = 'Level'
  AND l2_lvl_prop.Value    = '2'
  
  --------
  SELECT
l2_cap.ea_guid as CLASSGUID, l2_cap.name, Brand.Name
FROM
  t_object AS l2_cap
  INNER JOIN
    t_package AS pl_pkg
    ON
      pl_pkg.Package_ID = l2_cap.Package_ID
  INNER JOIN
    t_objectproperties AS l2_id_prop
    ON
      l2_id_prop.Object_ID = l2_cap.Object_ID
  INNER JOIN
    t_objectproperties AS l2_lvl_prop
    ON
      l2_lvl_prop.Object_ID = l2_cap.Object_ID
INNER JOIN
	t_connector AS conn ON conn.Start_Object_ID = l2_cap.Object_ID
INNER JOIN 
	t_object AS Brand ON conn.End_Object_ID = Brand.Object_ID

 
WHERE
  pl_pkg.ea_guid           = '{9BD1E3C3-EA0A-465b-ADF8-313AC0E888F0}'
  AND l2_cap.Stereotype    = 'ArchiMate_ApplicationFunction'
  AND l2_id_prop.Property  = 'Capability ID'
  AND l2_lvl_prop.Property = 'Level'
  AND l2_lvl_prop.Value    = '2'
  AND  SUBSTRING_INDEX( l2_id_prop.Value, '.', 1) = '2'
  AND Brand.Stereotype='Brand'

  select
    target.Object_ID as startelementid, source.Name as GroupName, op.Value as Series, source.Object_ID as ObjectID
  from
    (((t_object source
    left join
      t_connector con
      on
        con.Start_Object_ID = source.Object_ID)
    join
      t_object target
      on
        target.Object_ID = con.End_Object_ID)
    left join
      t_objectproperties op
      on
        op.Object_ID=target.Object_ID)
  where
    source.Stereotype    ='ArchiMate_WorkPackage'
    and target.Stereotype='ArchiMate_ApplicationComponent'
    and op.Property      = 'Health Indicator'
	
	
-- Component linked to component
SELECT t_object.Name AS 'App', t_object_1.Name AS 'Connected App'
FROM (t_object INNER JOIN t_connector ON t_object.Object_ID = t_connector.Start_Object_ID) 
INNER JOIN t_object AS t_object_1 ON t_connector.End_Object_ID = t_object_1.Object_ID
WHERE (((t_object.Stereotype)='dApplicationComponent') 
AND ((t_object_1.Stereotype)='dApplicationComponent') 
AND ((t_connector.Connector_Type)='Assembly'))
ORDER BY t_object.Name;
  
-- 13 Application by owner
  Select app.name as Role, owner.value as Owner
FROM t_object AS app
INNER JOIN t_objectproperties AS owner ON owner.Object_ID = app.Object_ID

where
app.Stereotype='dApplicationComponent' 
AND owner.Property = 'owner'
ORDER BY owner.value DESC

-- 14 business process value
SELECT tv.Value AS Series
FROM t_objectproperties tv
INNER JOIN t_object o ON o.Object_ID = tv.Object_ID
WHERE tv.Property in ('ProcessCriticality') 
AND (o.Stereotype='dBusinessProcess')



