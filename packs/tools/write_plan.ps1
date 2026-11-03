# Writes a pack plan (build_plan.py) into the repository open in EA, through COM.
# Re-runnable: the ledger maps each source GUID (element, attribute, literal) to its EA GUID,
# so existing items are updated in place, never duplicated. The ledger is saved as it goes.
# usage: write_plan.ps1 -Plan plan.json -Ledger ledger.json -TargetPackageGuid {...} [-Apply]
param([string]$Plan, [string]$Ledger, [string]$TargetPackageGuid, [switch]$Apply)
$ErrorActionPreference = "Stop"
$r = [Runtime.InteropServices.Marshal]::GetActiveObject("EA.App").Repository
"Repository: " + $r.ConnectionString
$target = $r.GetPackageByGuid($TargetPackageGuid)
if (-not $target) { throw "target package $TargetPackageGuid not found in the open repository" }
"Target: " + $target.Name + $(if ($Apply) { "  (APPLY)" } else { "  (DRY RUN)" })
$p = Get-Content -Raw -Encoding UTF8 $Plan | ConvertFrom-Json
$map = @{}
if (Test-Path $Ledger) { (Get-Content -Raw -Encoding UTF8 $Ledger | ConvertFrom-Json).PSObject.Properties | % { $map[$_.Name] = $_.Value } }
function SaveLedger { $o = [ordered]@{}; foreach ($k in $map.Keys) { $o[$k] = $map[$k] }; [IO.File]::WriteAllText($Ledger, ($o | ConvertTo-Json), (New-Object Text.UTF8Encoding($false))) }
if ($Apply) { $r.EnableUIUpdates = $false; $r.BatchAppend = $true }

function SubPackage($parentPkg, $name) {
  foreach ($x in $parentPkg.Packages) { if ($x.Name -ceq $name) { return $x } }
  if (-not $Apply) { return $null }
  $n = $parentPkg.Packages.AddNew($name, "Package"); [void]$n.Update(); $parentPkg.Packages.Refresh(); return $n
}
function SetTag($obj, $name, $value) {
  $tv = $null; foreach ($x in $obj.TaggedValues) { if ($x.Name -ceq $name) { $tv = $x; break } }
  if (-not $tv) { $tv = $obj.TaggedValues.AddNew($name, "") }
  $tv.Value = [string]$value; [void]$tv.Update()
}

# ---------------------------------------------------------------- packages
$pkgs = @{}
foreach ($k in $p.packages) {
  $par = if ($k.parent) { $pkgs[$k.parent] } else { $target }
  $pkgs[$k.key] = if ($par) { SubPackage $par $k.name } else { $null }
}
"packages: $($p.packages.Count)"

# ---------------------------------------------------------------- elements, attributes, literals
$created = 0; $updated = 0; $n = 0
foreach ($e in $p.elements) {
  $pkg = $pkgs[$e.package]; $el = $null
  if ($map.ContainsKey($e.sourceGuid)) { $el = $r.GetElementByGuid($map[$e.sourceGuid]) }
  if (-not $Apply) { if ($el) { $updated++ } else { $created++ }; continue }
  if (-not $el) {
    $el = $pkg.Elements.AddNew($e.name, $e.type)
    if ($e.stereotype) { $el.StereotypeEx = $e.stereotype }
    [void]$el.Update(); $created++
  } else {
    if ($el.PackageID -ne $pkg.PackageID) { $el.PackageID = $pkg.PackageID }; $updated++
  }
  $el.Name = $e.name; $el.Notes = $e.notes; [void]$el.Update()
  foreach ($t in $e.tags.PSObject.Properties) { SetTag $el $t.Name $t.Value }
  $map[$e.sourceGuid] = $el.ElementGUID
  $items = @(); if ($e.attributes) { $items = $e.attributes } elseif ($e.literals) { $items = $e.literals }
  foreach ($a in $items) {
    $at = $null
    if ($map.ContainsKey($a.sourceGuid)) { foreach ($x in $el.Attributes) { if ($x.AttributeGUID -eq $map[$a.sourceGuid]) { $at = $x; break } } }
    if (-not $at) { $at = $el.Attributes.AddNew($a.name, $(if ($a.type) { $a.type } else { "" })) }
    $at.Name = $a.name
    if ($e.attributes) {
      $at.Type = $a.type; $at.Notes = $a.notes; $at.LowerBound = [string]$a.lower; $at.UpperBound = [string]$a.upper
      $at.Visibility = $a.visibility; $at.IsStatic = $a.isStatic; $at.IsConst = $a.isConst; $at.IsOrdered = $a.isOrdered; $at.Pos = $a.pos
      $at.ClassifierID = $(if ($a.classifier -and $map.ContainsKey($a.classifier)) { $r.GetElementByGuid($map[$a.classifier]).ElementID } else { 0 })
    }
    [void]$at.Update()
    $map[$a.sourceGuid] = $at.AttributeGUID
  }
  if ($items.Count) { $el.Attributes.Refresh() }
  $n++; if ($n % 250 -eq 0) { SaveLedger; "  elements: $n" }
}
if ($Apply) { SaveLedger }
"elements: created $created, updated $updated"

# ---------------------------------------------------------------- connectors
$cAdded = 0; $cKept = 0; $n = 0
foreach ($c in $p.connectors) {
  if (-not ($map.ContainsKey($c.source) -and $map.ContainsKey($c.target))) { continue }
  if (-not $Apply) { $cAdded++; continue }
  $s = $r.GetElementByGuid($map[$c.source]); $t = $r.GetElementByGuid($map[$c.target])
  $st = if ($c.stereotype) { $c.stereotype -replace '^.*::', '' } else { "" }
  $exists = $false
  foreach ($x in $s.Connectors) {
    if ($x.ClientID -eq $s.ElementID -and $x.SupplierID -eq $t.ElementID -and $x.Type -eq $c.type -and $x.Stereotype -eq $st) {
      # two associations between the same classes are told apart by their role names and multiplicities
      if (-not $c.ends -or ($x.ClientEnd.Role -eq $c.ends.sourceRole -and $x.SupplierEnd.Role -eq $c.ends.targetRole -and $x.SupplierEnd.Cardinality -eq $c.ends.targetCard)) { $exists = $true; break }
    }
  }
  if ($exists) { $cKept++; continue }
  $k = $s.Connectors.AddNew("", $c.type); $k.SupplierID = $t.ElementID
  if ($c.stereotype) { $k.StereotypeEx = $c.stereotype }
  $k.Direction = "Source -> Destination"
  [void]$k.Update()
  if ($c.ends) {
    $k.ClientEnd.Cardinality = $c.ends.sourceCard; $k.ClientEnd.Role = $c.ends.sourceRole; $k.ClientEnd.Aggregation = [int]$c.ends.sourceAggregation
    $k.ClientEnd.Navigable = $(if ($c.ends.sourceNavigable) { "Navigable" } else { "Unspecified" }); [void]$k.ClientEnd.Update()
    $k.SupplierEnd.Cardinality = $c.ends.targetCard; $k.SupplierEnd.Role = $c.ends.targetRole; $k.SupplierEnd.Aggregation = [int]$c.ends.targetAggregation
    $k.SupplierEnd.Navigable = $(if ($c.ends.targetNavigable) { "Navigable" } else { "Unspecified" }); [void]$k.SupplierEnd.Update()
    [void]$k.Update()
  }
  $cAdded++
  $n++; if ($n % 1000 -eq 0) { "  connectors: $n" }
}
"connectors: added $cAdded, already there $cKept"
if ($Apply) { $r.BatchAppend = $false; $r.EnableUIUpdates = $true; $r.RefreshModelView($target.PackageID) }
