-- Select all roles and application linked with a dependency
select target.Name as series, source.Name as  groupname

from ((t_object source

left join t_connector con on con.Start_Object_ID = source.Object_ID)
join t_object target on target.Object_ID = con.End_Object_ID)

where
source.Stereotype='dRole'
and target.Stereotype='dApplicationComponent' 
and con.Connector_Type='Dependency'


--- variant
Select source.name as Role, target.name as Application
from t_object source

left join t_connector con on con.Start_Object_ID = source.Object_ID
join t_object target on target.Object_ID = con.End_Object_ID

where
source.Stereotype='dRole'
and target.Stereotype='dApplicationComponent' 
and con.Connector_Type='Dependency'


-- select all the applications connected with other applications
SELECT App.Name AS name, ConnectedApp.Name AS ConnectedAppName
FROM t_object as App
INNER JOIN t_connector ON App.Object_ID = t_connector.Start_Object_ID 
INNER JOIN t_object AS ConnectedApp ON t_connector.End_Object_ID = ConnectedApp.Object_ID
WHERE App.Stereotype='dApplicationComponent' 
AND ConnectedApp.Stereotype='dApplicationComponent' 
AND t_connector.Connector_Type='Assembly'
ORDER BY name

--  SELECT Application Cost by Capability
SELECT SUM(cost_prop.Value) AS ChartValue, Capability.Name AS Series
FROM t_object AS app
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS type_prop ON type_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS maint_prop ON maint_prop.Object_ID = app.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS Capability ON conn.End_Object_ID = Capability.Object_ID
WHERE app.Stereotype = 'dApplicationComponent'  
AND cost_prop.Property = ('Cost')
AND Capability.Stereotype = 'dCapability'  
GROUP BY Capability.Name
ORDER BY SUM(cost_prop.Value) DESC
Limit 15;


--  SELECT LogicalApplication Cost by Capability
SELECT SUM(cost_prop.Value) AS ChartValue, Capability.Name AS Series
FROM t_object AS app
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS type_prop ON type_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS maint_prop ON maint_prop.Object_ID = app.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS Capability ON conn.End_Object_ID = Capability.Object_ID
WHERE app.Stereotype = 'dlogicalAppComponent'  
AND cost_prop.Property = ('Cost')
AND Capability.Stereotype = 'dCapability'  
GROUP BY Capability.Name
ORDER BY SUM(cost_prop.Value) DESC
Limit 15;


--- select the average value of the KPI aggregated under a measurement area
SELECT
           AVG(CurrentLevel.Value)   AS ChartValue
         , dMeasurementGrouping.Name AS Series
FROM t_object AS KPI
           INNER JOIN  t_objectproperties AS CurrentLevel
                      ON CurrentLevel.Object_ID = KPI.Object_ID
           INNER JOIN t_connector AS connON conn.Start_Object_ID = KPI.Object_ID
           INNER JOIN t_object AS dMeasurementGrouping ON conn.End_Object_ID = dMeasurementGrouping.Object_ID
WHERE
           KPI.Stereotype                      = ('dMeasurementIndicator')
           AND CurrentLevel.Property           = ('CurrentLevel')
           AND dMeasurementGrouping.Stereotype = ('dMeasurementGrouping')

--- select the average value and the expected value of the KPI aggregated under a measurement area
SELECT AVG(CAST(CurrentLevel.Value as INT)) AS yValue, AVG(CAST(SatisfactionLevel.Value as INT)) AS xValue, dMeasurementGrouping.Name AS Series
FROM t_object AS KPI
INNER JOIN t_objectproperties AS CurrentLevel ON CurrentLevel.Object_ID = KPI.Object_ID
INNER JOIN t_objectproperties AS SatisfactionLevel ON SatisfactionLevel.Object_ID = KPI.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = KPI.Object_ID
INNER JOIN t_object AS dMeasurementGrouping ON conn.End_Object_ID = dMeasurementGrouping.Object_ID
WHERE KPI.Stereotype = ('dMeasurementIndicator')  
AND SatisfactionLevel.Property = ('SatisfactionLevel')
AND CurrentLevel.Property = ('CurrentLevel')
AND dMeasurementGrouping.Stereotype = ('dMeasurementGrouping')
GROUP BY dMeasurementGrouping.Name
ORDER BY SUM(CAST(CurrentLevel.Value as INT)) DESC

--- variation for DOC gen template selector
SELECT AVG(CAST(CurrentLevel.Value as INT)) AS CurrentValue, AVG(CAST(SatisfactionLevel.Value as INT)) AS TargetValue, dMeasurementGrouping.Name AS Name, dMeasurementGrouping.Note AS Notes 
FROM t_object AS KPI
INNER JOIN t_objectproperties AS CurrentLevel ON CurrentLevel.Object_ID = KPI.Object_ID
INNER JOIN t_objectproperties AS SatisfactionLevel ON SatisfactionLevel.Object_ID = KPI.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = KPI.Object_ID
INNER JOIN t_object AS dMeasurementGrouping ON conn.End_Object_ID = dMeasurementGrouping.Object_ID
WHERE KPI.Stereotype = ('dMeasurementIndicator')  
AND SatisfactionLevel.Property = ('SatisfactionLevel')
AND CurrentLevel.Property = ('CurrentLevel')
AND dMeasurementGrouping.Stereotype = ('dMeasurementGrouping')
GROUP BY dMeasurementGrouping.Name
ORDER BY SUM(CAST(CurrentLevel.Value as INT)) DESC


--- SQL version

SELECT AVG(CAST(CurrentLevel.Value as INT)) AS ChartValue, dMeasurementGrouping.Name AS Series
FROM t_object AS KPI
INNER JOIN t_objectproperties AS CurrentLevel ON CurrentLevel.Object_ID = KPI.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = KPI.Object_ID
INNER JOIN t_object AS dMeasurementGrouping ON conn.End_Object_ID = dMeasurementGrouping.Object_ID
WHERE KPI.Stereotype = ('dMeasurementIndicator')  
AND CurrentLevel.Property = ('CurrentLevel')
AND dMeasurementGrouping.Stereotype = ('dMeasurementGrouping')
GROUP BY dMeasurementGrouping.Name
ORDER BY SUM(CAST(CurrentLevel.Value as INT)) DESC

--- select the average value and the expected value of the KPI aggregated under a measurement area
SELECT AVG(CAST(CurrentLevel.Value as INT)) AS yValue, AVG(CAST(SatisfactionLevel.Value as INT)) AS xValue, dMeasurementGrouping.Name AS Series
FROM t_object AS KPI
INNER JOIN t_objectproperties AS CurrentLevel ON CurrentLevel.Object_ID = KPI.Object_ID
INNER JOIN t_objectproperties AS SatisfactionLevel ON SatisfactionLevel.Object_ID = KPI.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = KPI.Object_ID
INNER JOIN t_object AS dMeasurementGrouping ON conn.End_Object_ID = dMeasurementGrouping.Object_ID
WHERE KPI.Stereotype = ('dMeasurementIndicator')  
AND SatisfactionLevel.Property = ('SatisfactionLevel')
AND CurrentLevel.Property = ('CurrentLevel')
AND dMeasurementGrouping.Stereotype = ('dMeasurementGrouping')
GROUP BY dMeasurementGrouping.Name
ORDER BY SUM(CAST(CurrentLevel.Value as INT)) DESC

-- select all Measuremnt indicators under a Business capability
SELECT KPI.Name AS Name, AVG(CAST(CurrentLevel.Value as INT)) AS CurrentValue, AVG(CAST(SatisfactionLevel.Value as INT)) AS TargetValue
FROM t_object AS KPI
INNER JOIN t_objectproperties AS CurrentLevel ON CurrentLevel.Object_ID = KPI.Object_ID
INNER JOIN t_objectproperties AS SatisfactionLevel ON SatisfactionLevel.Object_ID = KPI.Object_ID
INNER JOIN t_connector AS conn ON conn.End_Object_ID= KPI.Object_ID
INNER JOIN t_object AS BusinessCapability ON conn.Start_Object_ID  = BusinessCapability.Object_ID
WHERE KPI.Stereotype = ('dMeasurementIndicator')  
AND SatisfactionLevel.Property = ('SatisfactionLevel')
AND CurrentLevel.Property = ('CurrentLevel')
AND BusinessCapability.Stereotype = ('dCapability')
GROUP BY Name
ORDER BY CurrentValue DESC

-- variation select all Measuremnt indicators under a Business capability
SELECT BusinessCapability.Name As "Capability", KPI.Name AS Name, AVG(CAST(CurrentLevel.Value as INT)) AS CurrentValue, AVG(CAST(SatisfactionLevel.Value as INT)) AS TargetValue 
FROM t_object AS KPI
INNER JOIN t_objectproperties AS CurrentLevel ON CurrentLevel.Object_ID = KPI.Object_ID
INNER JOIN t_objectproperties AS SatisfactionLevel ON SatisfactionLevel.Object_ID = KPI.Object_ID
INNER JOIN t_connector AS conn ON conn.End_Object_ID= KPI.Object_ID
INNER JOIN t_object AS BusinessCapability ON conn.Start_Object_ID  = BusinessCapability.Object_ID
WHERE KPI.Stereotype = ('dMeasurementIndicator')  
AND SatisfactionLevel.Property = ('SatisfactionLevel')
AND CurrentLevel.Property = ('CurrentLevel')
AND BusinessCapability.Stereotype = ('dCapability')


--- select all Measuremnt indicators under a Process
SELECT   AVG(CAST ( CurrentLevel.Value as Int))   AS ChartValue, 
 AVG(CAST ( SatisfactionLevel.Value as Int))   AS SatisfactionLevel, 
dMeasurementGrouping.Name AS Series
FROM t_object AS KPI
           INNER JOIN  t_objectproperties AS CurrentLevel ON 
           (CurrentLevel.Object_ID = KPI.Object_ID AND    CurrentLevel.Property           = ('CurrentLevel'))
             INNER JOIN  t_objectproperties AS SatisfactionLevel ON 
           (SatisfactionLevel.Object_ID = KPI.Object_ID AND    SatisfactionLevel.Property           = ('SatisfactionLevel'))
           INNER JOIN t_connector AS conn ON conn.End_Object_ID = KPI.Object_ID
           INNER JOIN t_object AS dMeasurementGrouping ON conn.Start_Object_ID = dMeasurementGrouping.Object_ID
WHERE
           KPI.Stereotype                      = ('TMF_Metric')
         
           AND dMeasurementGrouping.Stereotype = ('TMF_Process')
 
GROUP BY dMeasurementGrouping.Name



-- SELECT all the features that are set to be true and realize the maturity level of a Business Capability
SELECT feature.Name AS FeatName, Capability.Name AS CapName 
FROM t_object AS feature

INNER JOIN t_connector AS conn ON conn.Start_Object_ID = feature.Object_ID
INNER JOIN t_objectproperties AS FeatStatus ON FeatStatus.Object_ID = feature.Object_ID
INNER JOIN t_object AS Capability ON conn.End_Object_ID = Capability.Object_ID
WHERE feature.Stereotype = 'dFeature'  
AND Capability.Stereotype = 'dCapability'  
AND FeatStatus.Property=('Status')
AND FeatStatus.Value=('true')

--- Select all the AiaB Capabilities with category "aiab"

SELECT distinct CapId.Value as CapID,  Capability.Name AS CapName, AsIs.value AS AsIs, ToBe.value AS ToBe 
FROM t_object AS Capability

INNER JOIN t_objectproperties AS AsIs ON AsIs.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS ToBe ON ToBe.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS category ON category.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS CapID ON CapID.Object_ID = Capability.Object_ID
 
WHERE Capability.Stereotype = 'dCapability'  
AND AsIs.Property=('Increments')
AND ToBe.property=('IncrementsToBe')
And category.property=('Category')
AND category.value=('AiaB')
AND CapID.Property=('ID')
Order by CapId.Value ASC

--- Select all the AiaB Capabilities with category "aiab", add numerical values
SELECT distinct CapId.Value as CapID,  Capability.Name AS CapName, AsIs.value AS AsIs,  replace(replace(replace(replace(replace(replace(AsIs.value , 'None', '0'), 'Initial', '1'), 'UnderDevelopment', '2'),'Defined', '3'),'Managed', '4'), 'Measured', '5')  AS AsIsNum, ToBe.value AS ToBe, replace(replace(replace(replace(replace(replace(ToBe.value , 'None', '0'), 'Initial', '1'), 'UnderDevelopment', '2'),'Defined', '3'),'Managed', '4'), 'Measured', '5')  AS ToBeNum 
FROM t_object AS Capability

INNER JOIN t_objectproperties AS AsIs ON AsIs.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS ToBe ON ToBe.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS category ON category.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS CapID ON CapID.Object_ID = Capability.Object_ID
 
WHERE Capability.Stereotype = 'dCapability'  
AND AsIs.Property=('Increments')
AND ToBe.property=('IncrementsToBe')
And category.property=('Category')
AND category.value=('AiaB')
AND CapID.Property=('ID')
Order by CapId.Value ASC

--- calculate average maturity as-is and to-be for children capabilities connected with aggregations
SELECT   Capability.Name AS CapName, 
FORMAT(AVG(CAST(replace(replace(replace(replace(replace(replace(AsIs.value , 'None', '0'), 'Initial', '1'), 'UnderDevelopment', '2'),'Defined', '3'),'Managed', '4'), 'Measured', '5')AS INT)),2)  AS AsIsNum, 
FORMAT(AVG(CAST(replace(replace(replace(replace(replace(replace(ToBe.value , 'None', '0'), 'Initial', '1'), 'UnderDevelopment', '2'),'Defined', '3'),'Managed', '4'), 'Measured', '5')AS INT)),2)  AS ToBeNum 
FROM t_object AS Capability

INNER JOIN t_connector AS conn ON conn.End_Object_ID = Capability.Object_ID
INNER JOIN t_object AS ChildCapability ON conn.start_Object_ID = ChildCapability.Object_ID

INNER JOIN t_objectproperties AS AsIs ON AsIs.Object_ID = ChildCapability.Object_ID
INNER JOIN t_objectproperties AS ToBe ON ToBe.Object_ID = ChildCapability.Object_ID
INNER JOIN t_objectproperties AS category ON category.Object_ID = ChildCapability.Object_ID
 
WHERE Capability.Stereotype = 'dCapability'  
AND ChildCapability.Stereotype = 'dCapability'  
AND AsIs.Property=('Increments')
AND ToBe.property=('IncrementsToBe')
And category.property=('Category')
AND category.value=('AiaB')
AND conn.Connector_Type=('Aggregation')
group by CapName
Order by CapName ASC

--- calculate average capability related risk  for children capabilities connected with aggregations
SELECT Capability.Name AS CapName, FORMAT(AVG(CAST(Risk.value AS INT)),2) AS Risk 
FROM t_object AS Capability

INNER JOIN t_connector AS conn ON conn.End_Object_ID = Capability.Object_ID
INNER JOIN t_object AS ChildCapability ON conn.start_Object_ID = ChildCapability.Object_ID
INNER JOIN t_objectproperties AS Risk ON Risk.Object_ID = ChildCapability.Object_ID
INNER JOIN t_objectproperties AS category ON category.Object_ID = ChildCapability.Object_ID
 
WHERE Capability.Stereotype = 'dCapability'  
AND ChildCapability.Stereotype = 'dCapability'  
AND Risk.Property=('Risk')
And category.property=('Category')
AND category.value=('AiaB')
AND conn.Connector_Type=('Aggregation')
group by CapName
Order by CapName ASC

--- calculate average capability related criticality   for children capabilities connected with aggregations
SELECT Capability.Name AS CapName, FORMAT(AVG(CAST(criticality.value AS INT)),2) AS criticality 
FROM t_object AS Capability

INNER JOIN t_connector AS conn ON conn.End_Object_ID = Capability.Object_ID
INNER JOIN t_object AS ChildCapability ON conn.start_Object_ID = ChildCapability.Object_ID
INNER JOIN t_objectproperties AS criticality ON criticality.Object_ID = ChildCapability.Object_ID
INNER JOIN t_objectproperties AS category ON category.Object_ID = ChildCapability.Object_ID
 
WHERE Capability.Stereotype = 'dCapability'  
AND ChildCapability.Stereotype = 'dCapability'  
AND criticality.Property=('criticality')
And category.property=('Category')
AND category.value=('AiaB')
AND conn.Connector_Type=('Aggregation')
group by CapName
Order by CapName ASC

--- calculate total capability cost  from children capabilities connected with aggregations
SELECT Capability.Name AS CapName, SUM(CAST(Cost.value AS INT)) AS Cost 
FROM t_object AS Capability

INNER JOIN t_connector AS conn ON conn.End_Object_ID = Capability.Object_ID
INNER JOIN t_object AS ChildCapability ON conn.start_Object_ID = ChildCapability.Object_ID
INNER JOIN t_objectproperties AS Cost ON Cost.Object_ID = ChildCapability.Object_ID
INNER JOIN t_objectproperties AS category ON category.Object_ID = ChildCapability.Object_ID
 
WHERE Capability.Stereotype = 'dCapability'  
AND ChildCapability.Stereotype = 'dCapability'  
AND Cost.Property=('Cost')
And category.property=('Category')
AND category.value=('AiaB')
AND conn.Connector_Type=('Aggregation')
group by CapName
Order by CapName ASC

--- Capability Detail
--- Select all applications connected to a AiaB Capabilities with category "aiab" (connected with a trace)

SELECT  Capability.Name AS CapName, SupportingApplication.Name AS SupportingApplication, bizSatisfaction.Value As Satisfaction
FROM t_object AS Capability
INNER JOIN t_connector as relationship ON relationship.End_Object_ID= Capability.Object_ID 
INNER JOIN t_object AS SupportingApplication  ON relationship.Start_Object_ID = SupportingApplication.Object_ID

INNER JOIN t_objectproperties AS category ON category.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS bizSatisfaction ON bizSatisfaction.Object_ID = SupportingApplication.Object_ID


WHERE SupportingApplication.stereotype = ('dApplicationComponent')
AND Capability.Stereotype = ('dCapability')  
And category.property=('Category')
AND category.value=('AiaB') OR category.value=('IT4IT')

AND bizSatisfaction.Property = ('BizSatisfaction')
Group by Capability.Name 
Order BY  Capability.Name 

--- select all Roles associated with Capabilities

SELECT distinct Capability.Name AS CapName, Role.Name AS SupportingRole, FTES.Value as FullTimeEquivalent 
FROM t_object AS Capability
INNER JOIN t_connector as relationship ON relationship.End_Object_ID= Capability.Object_ID 
INNER JOIN t_object AS Role  ON relationship.Start_Object_ID = Role.Object_ID

INNER JOIN t_objectproperties AS category ON category.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS CapID ON CapID.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS FTES ON FTES.Object_ID = Role.Object_ID

WHERE Role.stereotype = ('dRole')
AND Capability.Stereotype = ('dCapability')  
And category.property=('Category')
AND category.value=('IT4IT') OR category.value=('AiaB') 
AND CapID.Property=('ID')
AND FTES.Property=('#FTEs') 
AND FTES.Value IS NOT NULL
Group by CapName
Order BY  CapName


-- Select all processes and Biz Criticality  that are connected with a Capability
SELECT distinct Capability.Name AS CapName, Process.Name AS SupportingProcess, ProcessCriticality.Value as ProcessCriticality 
FROM t_object AS Capability
INNER JOIN t_connector as relationship ON relationship.End_Object_ID= Capability.Object_ID 
INNER JOIN t_object AS Process  ON relationship.Start_Object_ID = Process.Object_ID

INNER JOIN t_objectproperties AS category ON category.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS CapID ON CapID.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS ProcessCriticality ON ProcessCriticality.Object_ID = Process.Object_ID

WHERE Process.stereotype = ('dBusinessProcess')
AND Capability.Stereotype = ('dCapability')  
And category.property=('Category')

AND CapID.Property=('ID')
AND ProcessCriticality.Property=('ProcessCriticality')
Order BY  Capability.Name 

--- select all KPI connected to a capability, their current and expected level
SELECT distinct Capability.Name AS CapName, Process.Name AS SupportingProcess, CurrentLevel.Value as CurrentLevel 
FROM t_object AS Capability
INNER JOIN t_connector as relationship ON relationship.End_Object_ID= Capability.Object_ID 
INNER JOIN t_object AS Process  ON relationship.Start_Object_ID = Process.Object_ID

INNER JOIN t_objectproperties AS category ON category.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS CapID ON CapID.Object_ID = Capability.Object_ID
INNER JOIN t_objectproperties AS CurrentLevel ON CurrentLevel.Object_ID = Process.Object_ID

WHERE Process.stereotype = ('dMeasurementIndicator')
AND Capability.Stereotype = ('dCapability')  
And category.property=('Category')

AND CapID.Property=('ID')
AND CurrentLevel.Property=('CurrentLevel')
Order BY  Capability.Name 


--- select all KPI and current and aspected lavel
select T1.Name as KPIName, op.value as CurrentLevel, op2.value as SatisfactionLevel,  t1.ea_guid as classguid
from t_object as T1   
left join t_objectproperties op on (op.Object_ID=T1.Object_ID)
left join t_objectproperties op2 on (op2.Object_ID=T1.Object_ID)
WHERE 
--(T1.Name= 'Average utilization of servers and IT equipment') AND  
(T1.Stereotype= 'dMeasurementIndicator')  
AND (op.Property='CurrentLevel')
AND (op2.Property='SatisfactionLevel')


--- Select all the initiatives with the Tag 'kind'=selected select all the user stories attached and the EstimatedEffort
SELECT   Initiative.Name AS iniName, StartDate.Value As StartDate, EndDate.Value AS EndDate,  UserStory.Name AS UserStory, CAST(EstimatedEffort.Value as INT) as EstimatedEffort
 
FROM t_object AS Initiative
INNER JOIN t_connector as relationship ON relationship.End_Object_ID= Initiative.Object_ID 
INNER JOIN t_object AS UserStory  ON relationship.Start_Object_ID = UserStory.Object_ID

INNER JOIN t_objectproperties AS StartDate ON StartDate.Object_ID = Initiative.Object_ID
INNER JOIN t_objectproperties AS EndDate ON EndDate.Object_ID = Initiative.Object_ID
INNER JOIN t_objectproperties AS EstimatedEffort ON EstimatedEffort.Object_ID = UserStory.Object_ID

WHERE UserStory.stereotype = ('dUserStory')
AND Initiative.Stereotype = ('dInitiative')  
And StartDate.property=('startDate')
AND EndDate.Property=('finishDate')
AND EstimatedEffort.Property=('EstimatedEffort')
Order BY  Initiative.Name ASC, EstimatedEffort DESC;  

--- SELECT Inititive duration by sum of User Stories hours
SELECT  dInitiative.Name AS Initiative,  StartDate.Value As StartDate, EndDate.Value AS EndDate, SUM((CAST(cost_prop.Value as INT))) AS effort
FROM t_object AS dUserStory
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = dUserStory.Object_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = dUserStory.Object_ID
INNER JOIN t_object AS dInitiative ON conn.End_Object_ID = dInitiative.Object_ID
INNER JOIN t_objectproperties AS StartDate ON StartDate.Object_ID = dInitiative.Object_ID
INNER JOIN t_objectproperties AS EndDate ON EndDate.Object_ID = dInitiative.Object_ID
WHERE dUserStory.Stereotype = 'dUserStory'  
AND cost_prop.Property = ('EstimatedEffort')
And StartDate.property=('startDate')
AND EndDate.Property=('finishDate')
AND dInitiative.Stereotype = 'dInitiative'  
GROUP BY Initiative
ORDER BY Initiative ASC, effort DESC
Limit 15;

-- select all the applications aggregated under a logical application and calculates the costs
SELECT SUM(cost_prop.Value) AS ChartValue, tam_app.Name AS Series
FROM t_object AS app
INNER JOIN t_objectproperties AS cost_prop ON cost_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS type_prop ON type_prop.Object_ID = app.Object_ID
INNER JOIN t_objectproperties AS maint_prop ON maint_prop.Object_ID = app.Object_ID
INNER JOIN t_package AS pkg ON pkg.Package_ID = app.Package_ID
INNER JOIN t_connector AS conn ON conn.Start_Object_ID = app.Object_ID
INNER JOIN t_object AS tam_app ON conn.End_Object_ID = tam_app.Object_ID
WHERE app.Stereotype = 'dApplicationComponent'  

AND cost_prop.Property = 'Cost'
AND type_prop.Property = 'Category' 
AND type_prop.Value = 'Custom'

AND tam_app.Stereotype = 'dLogicalAppComponent' 

GROUP BY tam_app.Name
ORDER BY SUM(cost_prop.Value) DESC
Limit 15;


--- Select Document template
SELECT    DocName, t_document.ElementID, t_document.DocID, t_document.DocDate
from  t_document
where t_document.DocType = 'SSDOCSTYLE'


-- select instance interface

Select * 
from t_object
where t_object.name='Product Catalog Management API' 
AND t_object.Object_Type = 'RequiredInterface'
AND t_object.ea_guid = '{38C11A9B-0452-4470-B861-508320224A5E}'