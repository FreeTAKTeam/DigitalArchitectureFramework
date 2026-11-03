# Dumps a source package tree from an EA SQL Server repository to JSON, read-only.
# usage: extract_source.ps1 -Dsn "Industry Models" -RootPackageId 6191 -OutDir <dir>
# Writes packages, objects, tags, attributes and connectors of the tree as <OutDir>\raw_*.json.
param([string]$Dsn = "Industry Models", [int]$RootPackageId, [string]$OutDir)
$c = New-Object -ComObject ADODB.Connection
$c.Mode = 1
$c.CommandTimeout = 600
$c.Open("Provider=MSDASQL.1;Data Source=$Dsn;")
$tree = "WITH pk AS (SELECT Package_ID, Parent_ID, Name, CAST(Name AS varchar(4000)) AS path FROM t_package WHERE Package_ID=$RootPackageId UNION ALL SELECT p.Package_ID, p.Parent_ID, p.Name, CAST(t.path+'/'+p.Name AS varchar(4000)) FROM t_package p JOIN pk t ON p.Parent_ID=t.Package_ID)"

function Dump($name, $sql) {
  $rs = $c.Execute($sql)
  $n = $rs.Fields.Count
  $cols = @(); for ($i = 0; $i -lt $n; $i++) { $cols += $rs.Fields.Item($i).Name }
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('[')
  $first = $true; $count = 0
  while (-not $rs.EOF) {
    $o = [ordered]@{}
    for ($i = 0; $i -lt $n; $i++) { $v = $rs.Fields.Item($i).Value; if ($v -is [DBNull]) { $v = $null }; $o[$cols[$i]] = $v }
    if (-not $first) { [void]$sb.Append(",`n") }; $first = $false
    [void]$sb.Append(($o | ConvertTo-Json -Compress -Depth 2))
    $count++; $rs.MoveNext()
  }
  [void]$sb.Append(']')
  [IO.File]::WriteAllText((Join-Path $OutDir "raw_$name.json"), $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
  "$name : $count"
}

$inTree = "o.Package_ID IN (SELECT Package_ID FROM pk)"
Dump "packages" "$tree SELECT Package_ID id, Parent_ID parent, Name name, path FROM pk OPTION (MAXRECURSION 100)"
Dump "objects" "$tree SELECT o.Object_ID id, o.ea_guid guid, o.Object_Type type, o.Stereotype stereotype, o.Name name, CAST(o.Note AS varchar(max)) note, o.Package_ID package, o.ParentID parentElement FROM t_object o WHERE $inTree AND o.Object_Type NOT IN ('Package','Note','Text','Boundary','UMLDiagram') OPTION (MAXRECURSION 100)"
Dump "tags" "$tree SELECT t.Object_ID id, t.Property name, CAST(t.Value AS varchar(4000)) value, CAST(t.Notes AS varchar(max)) notes FROM t_objectproperties t JOIN t_object o ON o.Object_ID=t.Object_ID WHERE $inTree OPTION (MAXRECURSION 100)"
Dump "attributes" "$tree SELECT a.ID id, a.Object_ID owner, a.ea_guid guid, a.Name name, a.Type type, a.Classifier classifier, a.LowerBound lower, a.UpperBound upper, CAST(a.Notes AS varchar(max)) notes, a.Scope visibility, a.IsStatic isStatic, a.Const isConst, a.IsOrdered isOrdered, a.Pos pos, CAST(a.[Default] AS varchar(255)) defaultValue FROM t_attribute a JOIN t_object o ON o.Object_ID=a.Object_ID WHERE $inTree OPTION (MAXRECURSION 100)"
Dump "connectors" "$tree SELECT c.Connector_ID id, c.ea_guid guid, c.Connector_Type type, c.Stereotype stereotype, c.Start_Object_ID source, c.End_Object_ID target, c.SourceCard sourceCard, c.DestCard targetCard, c.SourceRole sourceRole, c.DestRole targetRole, c.SourceIsNavigable sourceNavigable, c.DestIsNavigable targetNavigable, c.SourceIsAggregate sourceAggregation, c.DestIsAggregate targetAggregation, c.Direction direction FROM t_connector c WHERE c.Start_Object_ID IN (SELECT o.Object_ID FROM t_object o WHERE $inTree) OR c.End_Object_ID IN (SELECT o.Object_ID FROM t_object o WHERE $inTree) OPTION (MAXRECURSION 100)"
$c.Close()
