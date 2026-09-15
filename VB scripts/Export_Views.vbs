Option Explicit

' ============================================================================
' EuroCom -> Dafrion View Exporter
' Target: Sparx Enterprise Architect internal VBScript engine
' Dafrion view contract: crates/dafrion-view
' DAF version: 6.3
'
' Version 0.2.0 changes:
' - resolves node semantic identities from the authoritative M1 Turtle export;
' - never fabricates element_<GUID> semantic IRIs;
' - exports only resources carrying a DAF model type;
' - records graphical-only and missing semantic objects in a CSV audit;
' - makes node occurrence IDs collision-safe;
' - resolves connector endpoints against exact semantic source/target IRIs;
' - removes stale *.view.json files before a new export.
' ============================================================================

Const SCRIPT_VERSION = "0.2.0"
Const ROOT_PACKAGE_GUID = "{2B098F05-3CC7-4637-9A68-0DAD07564747}"

Const DAF_MODEL_NAMESPACE = "https://freetakteam.github.io/DAF/model#"
Const DAF_INSTANCE_NAMESPACE = "https://freetakteam.github.io/DAF/instance#"
Const DAF_METAMODEL_NAMESPACE = "https://freetakteam.github.io/DAF/metamodel#"

' Authoritative semantic model produced by the EuroCom M1 RDF exporter.
Const SEMANTIC_TTL_PATH = "C:\Users\broth\Documents\work\ATAK\src\Dafrion\models\reference\eurocom\eurocom.ttl"

Const VIEW_IRI_BASE = "urn:dafrion:view:eurocom:"
Const VIEW_NODE_IRI_BASE = "urn:dafrion:view-node:eurocom:"
Const VIEW_CONNECTOR_IRI_BASE = "urn:dafrion:view-connector:eurocom:"

Const OUTPUT_FOLDER = "C:\tmp\Dafrion-EuroCom-views"
Const REPORT_FILE = "EuroCom-view-export.report.txt"
Const SKIPPED_OBJECT_AUDIT_FILE = "EuroCom-view-export.skipped-objects.csv"
Const MARGIN = 20
Const MIN_NODE_SIZE = 1
Const MAX_CONNECTOR_ERROR_DETAILS_PER_DIAGRAM = 5
Const MAX_SKIPPED_OBJECT_DETAILS_PER_DIAGRAM = 8

Const STATUS_RESOLVED = "resolved"
Const STATUS_GRAPHICAL_ONLY = "graphical-only"
Const STATUS_SEMANTIC_GAP = "semantic-gap"
Const STATUS_AMBIGUOUS = "ambiguous"
Const STATUS_MISSING_EA = "missing-ea-element"

' Semantic resource record indexes.
Const SR_IRI = 0
Const SR_IS_DAF_ELEMENT = 1
Const SR_IS_EXTERNAL = 2
Const SR_IS_PACKAGE = 3
Const SR_IS_RELATIONSHIP = 4
Const SR_TYPES = 5

' Cached EA element resolution record indexes.
Const ER_STATUS = 0
Const ER_IRI = 1
Const ER_GUID_KEY = 2
Const ER_RAW_GUID = 3
Const ER_NAME = 4
Const ER_TYPE = 5
Const ER_META_TYPE = 6
Const ER_STEREOTYPE = 7
Const ER_STEREOTYPE_EX = 8
Const ER_PACKAGE = 9
Const ER_IS_EXTERNAL = 10
Const ER_RDF_TYPES = 11
Const ER_REASON = 12

Dim gFso
Dim gDiagramCount
Dim gDiagramSkippedNoSemanticCount
Dim gNodeCount
Dim gExternalDafNodeCount
Dim gConnectorCount
Dim gHiddenConnectorCount
Dim gMissingConnectorCount
Dim gEndpointFallbackCount
Dim gInvalidBoundsCount
Dim gWarningCount
Dim gReport
Dim gSkippedObjectAudit

Dim gSemanticRelByGuid
Dim gSemanticResourcesByGuid
Dim gSemanticCollisionGuids
Dim gSemanticAmbiguousDafGuids
Dim gKnownDafStereotypes
Dim gSemanticTtlResolvedPath
Dim gSemanticResourceCount
Dim gSemanticDafElementCount
Dim gSemanticExternalResourceCount
Dim gSemanticExternalDafElementCount
Dim gSemanticPackageResourceCount
Dim gSemanticGuidCollisionCount
Dim gSemanticAmbiguousDafGuidCount
Dim gSemanticRelationshipCount
Dim gSemanticRelationshipUsedCount
Dim gSemanticEndpointReverseCount

Dim gElementResolutionById
Dim gConnectorInfoById
Dim gElementCacheHits
Dim gElementCacheMisses
Dim gConnectorCacheHits
Dim gConnectorCacheMisses
Dim gConnectorRuntimeErrorCount
Dim gUnresolvedEndpointConnectorCount
Dim gUnresolvedRelationshipConnectorCount
Dim gAmbiguousEndpointConnectorCount
Dim gDuplicateInstanceGuidOccurrenceCount

Dim gGraphicalOnlyObjectCount
Dim gSemanticGapObjectCount
Dim gAmbiguousObjectCount
Dim gMissingEaObjectCount

Dim gPathPointRegex
Dim gGuidInIriRegex

Sub Main()
    Dim rootPackage

    Set gFso = CreateObject("Scripting.FileSystemObject")

    Set gSemanticRelByGuid = CreateObject("Scripting.Dictionary")
    Set gSemanticResourcesByGuid = CreateObject("Scripting.Dictionary")
    Set gSemanticCollisionGuids = CreateObject("Scripting.Dictionary")
    Set gSemanticAmbiguousDafGuids = CreateObject("Scripting.Dictionary")
    Set gKnownDafStereotypes = CreateObject("Scripting.Dictionary")
    Set gElementResolutionById = CreateObject("Scripting.Dictionary")
    Set gConnectorInfoById = CreateObject("Scripting.Dictionary")

    gSemanticRelByGuid.CompareMode = 1
    gSemanticResourcesByGuid.CompareMode = 1
    gSemanticCollisionGuids.CompareMode = 1
    gSemanticAmbiguousDafGuids.CompareMode = 1
    gKnownDafStereotypes.CompareMode = 1
    gElementResolutionById.CompareMode = 1
    gConnectorInfoById.CompareMode = 1

    Set gPathPointRegex = CreateObject("VBScript.RegExp")
    gPathPointRegex.Global = True
    gPathPointRegex.IgnoreCase = True
    gPathPointRegex.Pattern = "(-?[0-9]+(\.[0-9]+)?)\s*:\s*(-?[0-9]+(\.[0-9]+)?)"

    Set gGuidInIriRegex = CreateObject("VBScript.RegExp")
    gGuidInIriRegex.Global = False
    gGuidInIriRegex.IgnoreCase = True
    gGuidInIriRegex.Pattern = "([0-9A-Fa-f]{8}[-_][0-9A-Fa-f]{4}[-_][0-9A-Fa-f]{4}[-_][0-9A-Fa-f]{4}[-_][0-9A-Fa-f]{12})"

    gDiagramCount = 0
    gDiagramSkippedNoSemanticCount = 0
    gNodeCount = 0
    gExternalDafNodeCount = 0
    gConnectorCount = 0
    gHiddenConnectorCount = 0
    gMissingConnectorCount = 0
    gEndpointFallbackCount = 0
    gInvalidBoundsCount = 0
    gWarningCount = 0

    gSemanticResourceCount = 0
    gSemanticDafElementCount = 0
    gSemanticExternalResourceCount = 0
    gSemanticExternalDafElementCount = 0
    gSemanticPackageResourceCount = 0
    gSemanticGuidCollisionCount = 0
    gSemanticAmbiguousDafGuidCount = 0
    gSemanticRelationshipCount = 0
    gSemanticRelationshipUsedCount = 0
    gSemanticEndpointReverseCount = 0

    gElementCacheHits = 0
    gElementCacheMisses = 0
    gConnectorCacheHits = 0
    gConnectorCacheMisses = 0
    gConnectorRuntimeErrorCount = 0
    gUnresolvedEndpointConnectorCount = 0
    gUnresolvedRelationshipConnectorCount = 0
    gAmbiguousEndpointConnectorCount = 0
    gDuplicateInstanceGuidOccurrenceCount = 0

    gGraphicalOnlyObjectCount = 0
    gSemanticGapObjectCount = 0
    gAmbiguousObjectCount = 0
    gMissingEaObjectCount = 0

    gSemanticTtlResolvedPath = ""
    gReport = ""
    gSkippedObjectAudit = _
        "status,reason,diagram_name,diagram_guid,ea_element_id,ea_element_guid," & _
        "name,ea_type,ea_meta_type,stereotype,stereotype_ex,package,semantic_iri,rdf_types" & vbCrLf

    EnsureFolder OUTPUT_FOLDER
    CleanPreviousExportFiles OUTPUT_FOLDER

    Session.Output ""
    Session.Output "=== Dafrion EuroCom View Exporter " & SCRIPT_VERSION & " ==="
    ReportLine "DAFRION EUROCOM VIEW EXPORT REPORT"
    ReportLine "Generated: " & CStr(Now)
    ReportLine "Exporter version: " & SCRIPT_VERSION
    ReportLine "DAF framework version: 6.3"
    ReportLine "Root package GUID: " & ROOT_PACKAGE_GUID
    ReportLine "Output folder: " & OUTPUT_FOLDER
    ReportLine "Preferred semantic model: " & SEMANTIC_TTL_PATH
    ReportLine "Identity policy: strict authoritative EA GUID -> exact Turtle subject IRI"
    ReportLine ""

    gSemanticTtlResolvedPath = ResolveSemanticTtlPath()
    If Len(gSemanticTtlResolvedPath) = 0 Then
        ReportLine "ERROR: authoritative M1 semantic model unavailable."
        ReportLine "Graphical Views were not generated because semantic identities cannot be resolved safely."
        gWarningCount = gWarningCount + 1
        WriteExportFiles
        Exit Sub
    End If

    ReportLine "Semantic model resolved: " & gSemanticTtlResolvedPath
    ReportLine "Indexing semantic resources and first-class relationships..."
    LoadSemanticModelIndex gSemanticTtlResolvedPath
    ReportLine "Semantic resources indexed: " & CStr(gSemanticResourceCount)
    ReportLine "DAF semantic elements indexed: " & CStr(gSemanticDafElementCount)
    ReportLine "External semantic resources indexed: " & CStr(gSemanticExternalResourceCount)
    ReportLine "External DAF semantic elements indexed: " & CStr(gSemanticExternalDafElementCount)
    ReportLine "Package resources indexed: " & CStr(gSemanticPackageResourceCount)
    ReportLine "EA GUIDs with multiple RDF resources: " & CStr(gSemanticGuidCollisionCount)
    ReportLine "EA GUIDs with multiple DAF element candidates: " & CStr(gSemanticAmbiguousDafGuidCount)
    ReportLine "First-class relationships indexed: " & CStr(gSemanticRelationshipCount)
    ReportLine ""

    If gSemanticDafElementCount = 0 Then
        ReportLine "ERROR: no resources typed in the DAF model namespace were indexed."
        ReportLine "The Turtle file is not a usable authoritative EuroCom M1 export."
        gWarningCount = gWarningCount + 1
        WriteExportFiles
        Exit Sub
    End If

    If gSemanticRelationshipCount = 0 Then
        ReportLine "ERROR: no first-class relationships with dafm:source and dafm:target were indexed."
        ReportLine "The Turtle file is not a usable authoritative EuroCom M1 export."
        gWarningCount = gWarningCount + 1
        WriteExportFiles
        Exit Sub
    End If

    On Error Resume Next
    Set rootPackage = Repository.GetPackageByGuid(ROOT_PACKAGE_GUID)
    If Err.Number <> 0 Or rootPackage Is Nothing Then
        ReportLine "ERROR: Cannot resolve root package " & ROOT_PACKAGE_GUID
        ReportLine "EA error: " & Err.Description
        Err.Clear
        On Error GoTo 0
        gWarningCount = gWarningCount + 1
        WriteExportFiles
        Exit Sub
    End If
    On Error GoTo 0

    ReportLine "Root package: " & rootPackage.Name
    ReportLine ""

    ExportPackageRecursive rootPackage

    ReportLine ""
    ReportLine "SUMMARY"
    ReportLine "Diagrams exported: " & CStr(gDiagramCount)
    ReportLine "Diagrams skipped because no DAF semantic node was resolvable: " & CStr(gDiagramSkippedNoSemanticCount)
    ReportLine "DAF node occurrences exported: " & CStr(gNodeCount)
    ReportLine "External DAF node occurrences exported: " & CStr(gExternalDafNodeCount)
    ReportLine "Graphical-only/non-DAF occurrences skipped: " & CStr(gGraphicalOnlyObjectCount)
    ReportLine "DAF semantic export gaps skipped: " & CStr(gSemanticGapObjectCount)
    ReportLine "Ambiguous semantic object occurrences skipped: " & CStr(gAmbiguousObjectCount)
    ReportLine "Missing EA element occurrences skipped: " & CStr(gMissingEaObjectCount)
    ReportLine "Visible connector occurrences exported: " & CStr(gConnectorCount)
    ReportLine "Hidden connector occurrences skipped: " & CStr(gHiddenConnectorCount)
    ReportLine "Diagram links with missing EA connector skipped: " & CStr(gMissingConnectorCount)
    ReportLine "Connectors missing from semantic relationship index skipped: " & CStr(gUnresolvedRelationshipConnectorCount)
    ReportLine "Connector occurrences skipped for missing semantic endpoint occurrence: " & CStr(gUnresolvedEndpointConnectorCount)
    ReportLine "Connector occurrences skipped for ambiguous endpoint occurrence: " & CStr(gAmbiguousEndpointConnectorCount)
    ReportLine "Connector endpoints resolved by unique semantic occurrence fallback: " & CStr(gEndpointFallbackCount)
    ReportLine "Graphical endpoint orders reversed to match semantic source/target: " & CStr(gSemanticEndpointReverseCount)
    ReportLine "Duplicate EA InstanceGUID occurrences made collision-safe: " & CStr(gDuplicateInstanceGuidOccurrenceCount)
    ReportLine "Invalid/zero exported node bounds clamped: " & CStr(gInvalidBoundsCount)
    ReportLine "Connector runtime errors isolated: " & CStr(gConnectorRuntimeErrorCount)
    ReportLine "Element resolution cache: " & CStr(gElementCacheHits) & " hits / " & CStr(gElementCacheMisses) & " misses"
    ReportLine "Connector metadata cache: " & CStr(gConnectorCacheHits) & " hits / " & CStr(gConnectorCacheMisses) & " misses"
    ReportLine "Warnings: " & CStr(gWarningCount)
    ReportLine ""
    ReportLine "NOTES"
    ReportLine "- Every emitted ViewNode.element_id is the exact subject IRI found in the authoritative Turtle model."
    ReportLine "- No element_<GUID> semantic identity is manufactured by this exporter."
    ReportLine "- Only RDF resources with a type in the DAF model namespace are emitted as ViewNodes."
    ReportLine "- Notes, boundaries, packages, UML-only objects and missing resources are retained in the CSV audit."
    ReportLine "- Current dafrion-view has no graphical-only annotation occurrence; skipped objects are therefore not emitted as fake nodes."
    ReportLine "- Every emitted connector references an indexed first-class relationship and exact dafm:source/dafm:target endpoints."
    ReportLine "- Duplicate DiagramObject InstanceGUID values are made unique instead of producing duplicate ViewNode IDs."
    ReportLine "- Existing *.view.json files in the output folder are removed before export to prevent stale invalid files."
    ReportLine ""
    ReportLine "Skipped-object audit: " & OUTPUT_FOLDER & "\" & SKIPPED_OBJECT_AUDIT_FILE
    ReportLine "Export finished. Report: " & OUTPUT_FOLDER & "\" & REPORT_FILE

    WriteExportFiles
End Sub

Sub WriteExportFiles()
    WriteUtf8File OUTPUT_FOLDER & "\" & REPORT_FILE, gReport
    WriteUtf8File OUTPUT_FOLDER & "\" & SKIPPED_OBJECT_AUDIT_FILE, gSkippedObjectAudit
End Sub

Sub ExportPackageRecursive(pkg)
    Dim diagram
    Dim child
    Dim diagramIndex

    ReportLine "PACKAGE: " & CStr(pkg.Name) & " [diagrams=" & CStr(pkg.Diagrams.Count) & ", child packages=" & CStr(pkg.Packages.Count) & "]"

    diagramIndex = 0
    For Each diagram In pkg.Diagrams
        diagramIndex = diagramIndex + 1
        ReportLine "  START DIAGRAM " & CStr(diagramIndex) & "/" & CStr(pkg.Diagrams.Count) & _
                   ": " & CStr(diagram.Name) & " [objects=" & CStr(diagram.DiagramObjects.Count) & _
                   ", links=" & CStr(diagram.DiagramLinks.Count) & "]"

        On Error Resume Next
        ExportDiagram diagram
        If Err.Number <> 0 Then
            ReportLine "  ERROR DIAGRAM: " & CStr(diagram.Name) & _
                       " | " & CStr(Err.Number) & " - " & CStr(Err.Description)
            gWarningCount = gWarningCount + 1
            Err.Clear
        End If
        On Error GoTo 0
    Next

    For Each child In pkg.Packages
        ExportPackageRecursive child
    Next
End Sub

Sub ExportDiagram(diagram)
    Dim duidToNodeIds
    Dim elementIdToNodeId
    Dim occurrenceBaseCount
    Dim ordinalToNodeId
    Dim ordinalToResolution
    Dim elementIriToNodeIds
    Dim nodeIdToElementIri
    Dim minX, minY, maxX, maxY, haveExtent
    Dim dobj, dlink
    Dim leftX, rightX, topY, bottomY
    Dim x, y, w, h
    Dim points, pt
    Dim offsetX, offsetY
    Dim canvasWidth, canvasHeight
    Dim nodeJson, connectorJson, json
    Dim firstNode, firstConnector
    Dim nodeId, elementIri, diagramKey
    Dim outputPath
    Dim connectorOrdinal
    Dim viewId
    Dim stereotypeVisible
    Dim diagramDescription
    Dim pass1NodeOrdinal
    Dim nodeOrdinal
    Dim pointIndex
    Dim elementId
    Dim duid
    Dim connectorPiece
    Dim connectorErrNumber, connectorErrDescription
    Dim diagramConnectorErrors
    Dim diagramEndpointSkipped
    Dim diagramRelationshipSkipped
    Dim diagramAmbiguousEndpointSkipped
    Dim detailErrorsShown
    Dim skippedDetailsShown
    Dim zIndex
    Dim resolution
    Dim diagramSemanticNodes
    Dim diagramExternalDafNodes
    Dim diagramGraphicalOnly
    Dim diagramSemanticGaps
    Dim diagramAmbiguousObjects
    Dim diagramMissingEaObjects

    Set duidToNodeIds = CreateObject("Scripting.Dictionary")
    Set elementIdToNodeId = CreateObject("Scripting.Dictionary")
    Set occurrenceBaseCount = CreateObject("Scripting.Dictionary")
    Set ordinalToNodeId = CreateObject("Scripting.Dictionary")
    Set ordinalToResolution = CreateObject("Scripting.Dictionary")
    Set elementIriToNodeIds = CreateObject("Scripting.Dictionary")
    Set nodeIdToElementIri = CreateObject("Scripting.Dictionary")

    duidToNodeIds.CompareMode = 1
    elementIdToNodeId.CompareMode = 1
    occurrenceBaseCount.CompareMode = 1
    ordinalToNodeId.CompareMode = 1
    ordinalToResolution.CompareMode = 1
    elementIriToNodeIds.CompareMode = 1
    nodeIdToElementIri.CompareMode = 1

    minX = 0
    minY = 0
    maxX = 0
    maxY = 0
    haveExtent = False
    diagramConnectorErrors = 0
    diagramEndpointSkipped = 0
    diagramRelationshipSkipped = 0
    diagramAmbiguousEndpointSkipped = 0
    detailErrorsShown = 0
    skippedDetailsShown = 0

    diagramSemanticNodes = 0
    diagramExternalDafNodes = 0
    diagramGraphicalOnly = 0
    diagramSemanticGaps = 0
    diagramAmbiguousObjects = 0
    diagramMissingEaObjects = 0

    diagramKey = NormalizeGuid(SafeStringValue(diagram.DiagramGUID, ""))
    If Len(diagramKey) = 0 Then diagramKey = "diagram_" & CStr(SafeLongValue(diagram.DiagramID, 0))
    viewId = VIEW_IRI_BASE & diagramKey

    ' Pass 1: resolve semantic identity before creating any ViewNode occurrence.
    pass1NodeOrdinal = 0
    For Each dobj In diagram.DiagramObjects
        pass1NodeOrdinal = pass1NodeOrdinal + 1
        elementId = SafeLongValue(dobj.ElementID, 0)
        resolution = GetElementResolution(elementId)
        ordinalToResolution(CStr(pass1NodeOrdinal)) = resolution

        If SafeStringValue(resolution(ER_STATUS), "") = STATUS_RESOLVED Then
            leftX = SafeDoubleValue(dobj.Left, 0)
            rightX = SafeDoubleValue(dobj.Right, leftX + MIN_NODE_SIZE)
            topY = -SafeDoubleValue(dobj.Top, 0)
            bottomY = -SafeDoubleValue(dobj.Bottom, -MIN_NODE_SIZE)

            x = MinNumber(leftX, rightX)
            y = MinNumber(topY, bottomY)
            w = Abs(rightX - leftX)
            h = Abs(bottomY - topY)

            If w <= 0 Then w = MIN_NODE_SIZE
            If h <= 0 Then h = MIN_NODE_SIZE

            UpdateExtent x, y, haveExtent, minX, minY, maxX, maxY
            UpdateExtent x + w, y + h, haveExtent, minX, minY, maxX, maxY

            nodeId = BuildNodeOccurrenceId(diagramKey, dobj, occurrenceBaseCount)
            elementIri = SafeStringValue(resolution(ER_IRI), "")

            ordinalToNodeId(CStr(pass1NodeOrdinal)) = nodeId
            nodeIdToElementIri(nodeId) = elementIri

            duid = NormalizeGuid(SafeStringValue(dobj.InstanceGUID, ""))
            If Len(duid) > 0 Then AddNodeReference duidToNodeIds, duid, nodeId

            If elementId > 0 Then
                If Not elementIdToNodeId.Exists(CStr(elementId)) Then
                    elementIdToNodeId(CStr(elementId)) = nodeId
                End If
            End If
            AddNodeReference elementIriToNodeIds, elementIri, nodeId

            diagramSemanticNodes = diagramSemanticNodes + 1
            If SafeBoolValue(resolution(ER_IS_EXTERNAL), False) Then
                diagramExternalDafNodes = diagramExternalDafNodes + 1
            End If
        Else
            Select Case SafeStringValue(resolution(ER_STATUS), "")
                Case STATUS_GRAPHICAL_ONLY
                    diagramGraphicalOnly = diagramGraphicalOnly + 1
                    gGraphicalOnlyObjectCount = gGraphicalOnlyObjectCount + 1
                Case STATUS_SEMANTIC_GAP
                    diagramSemanticGaps = diagramSemanticGaps + 1
                    gSemanticGapObjectCount = gSemanticGapObjectCount + 1
                Case STATUS_AMBIGUOUS
                    diagramAmbiguousObjects = diagramAmbiguousObjects + 1
                    gAmbiguousObjectCount = gAmbiguousObjectCount + 1
                Case Else
                    diagramMissingEaObjects = diagramMissingEaObjects + 1
                    gMissingEaObjectCount = gMissingEaObjectCount + 1
            End Select
            RecordSkippedObject diagram, dobj, resolution, skippedDetailsShown
        End If
    Next

    ' Preserve connector route extents. This may retain whitespace formerly occupied by
    ' graphical-only objects, but it prevents valid imported routes from being clipped.
    For Each dlink In diagram.DiagramLinks
        If Not SafeBoolValue(dlink.IsHidden, False) Then
            Set points = ParseEaPathPoints(SafeStringValue(dlink.Path, ""))
            For pointIndex = 0 To points.Count - 1
                pt = points.Item(CStr(pointIndex))
                UpdateExtent SafeDoubleValue(pt(0), 0), SafeDoubleValue(pt(1), 0), _
                             haveExtent, minX, minY, maxX, maxY
            Next
        End If
    Next

    If Not haveExtent Then
        minX = 0
        minY = 0
        maxX = 100
        maxY = 100
    End If

    offsetX = MARGIN - minX
    offsetY = MARGIN - minY
    canvasWidth = (maxX - minX) + (2 * MARGIN)
    canvasHeight = (maxY - minY) + (2 * MARGIN)

    If canvasWidth <= 0 Then canvasWidth = 100
    If canvasHeight <= 0 Then canvasHeight = 100

    stereotypeVisible = Not DiagramStyleFlag(SafeDiagramExtendedStyle(diagram), "HideStereo", "1")
    diagramDescription = SafeDiagramNotes(diagram)

    nodeJson = ""
    firstNode = True

    ' Pass 2: serialize only nodes whose exact RDF subject is a DAF semantic element.
    nodeOrdinal = 0
    For Each dobj In diagram.DiagramObjects
        nodeOrdinal = nodeOrdinal + 1
        resolution = ordinalToResolution(CStr(nodeOrdinal))

        If SafeStringValue(resolution(ER_STATUS), "") = STATUS_RESOLVED Then
            leftX = SafeDoubleValue(dobj.Left, 0)
            rightX = SafeDoubleValue(dobj.Right, leftX + MIN_NODE_SIZE)
            topY = -SafeDoubleValue(dobj.Top, 0)
            bottomY = -SafeDoubleValue(dobj.Bottom, -MIN_NODE_SIZE)

            x = MinNumber(leftX, rightX) + offsetX
            y = MinNumber(topY, bottomY) + offsetY
            w = Abs(rightX - leftX)
            h = Abs(bottomY - topY)

            elementId = SafeLongValue(dobj.ElementID, 0)

            If w <= 0 Then
                w = MIN_NODE_SIZE
                gInvalidBoundsCount = gInvalidBoundsCount + 1
                Warn diagram, "Clamped zero/non-positive width for ElementID " & CStr(elementId)
            End If
            If h <= 0 Then
                h = MIN_NODE_SIZE
                gInvalidBoundsCount = gInvalidBoundsCount + 1
                Warn diagram, "Clamped zero/non-positive height for ElementID " & CStr(elementId)
            End If

            nodeId = ordinalToNodeId(CStr(nodeOrdinal))
            elementIri = SafeStringValue(resolution(ER_IRI), "")

            If Not firstNode Then nodeJson = nodeJson & "," & vbCrLf
            firstNode = False

            zIndex = SafeLongValue(dobj.Sequence, 0)

            nodeJson = nodeJson & "    {" & vbCrLf
            nodeJson = nodeJson & "      " & J("id") & ": " & J(nodeId) & "," & vbCrLf
            nodeJson = nodeJson & "      " & J("element_id") & ": " & J(elementIri) & "," & vbCrLf
            nodeJson = nodeJson & "      " & J("bounds") & ": {" & _
                       J("x") & ": " & N(x) & ", " & _
                       J("y") & ": " & N(y) & ", " & _
                       J("width") & ": " & N(w) & ", " & _
                       J("height") & ": " & N(h) & "}," & vbCrLf
            nodeJson = nodeJson & "      " & J("z_index") & ": " & CStr(zIndex) & "," & vbCrLf
            nodeJson = nodeJson & "      " & J("presentation") & ": " & _
                       BuildNodePresentationJson(dobj, stereotypeVisible) & "," & vbCrLf
            nodeJson = nodeJson & "      " & J("metadata") & ": " & _
                       BuildNodeOccurrenceMetadataJson(dobj, resolution) & vbCrLf
            nodeJson = nodeJson & "    }"

            gNodeCount = gNodeCount + 1
            If SafeBoolValue(resolution(ER_IS_EXTERNAL), False) Then
                gExternalDafNodeCount = gExternalDafNodeCount + 1
            End If
        End If
    Next

    connectorJson = ""
    firstConnector = True
    connectorOrdinal = 0

    ' Pass 3: emit only connectors whose semantic relationship and both semantic
    ' endpoint occurrences can be resolved without guessing.
    For Each dlink In diagram.DiagramLinks
        connectorOrdinal = connectorOrdinal + 1
        connectorPiece = ""
        connectorErrNumber = 0
        connectorErrDescription = ""

        On Error Resume Next
        connectorPiece = BuildConnectorOccurrenceJson( _
            diagram, dlink, diagramKey, connectorOrdinal, _
            duidToNodeIds, elementIriToNodeIds, nodeIdToElementIri, _
            offsetX, offsetY, diagramEndpointSkipped, diagramRelationshipSkipped, _
            diagramAmbiguousEndpointSkipped)
        connectorErrNumber = Err.Number
        connectorErrDescription = Err.Description
        Err.Clear
        On Error GoTo 0

        If connectorErrNumber <> 0 Then
            diagramConnectorErrors = diagramConnectorErrors + 1
            gConnectorRuntimeErrorCount = gConnectorRuntimeErrorCount + 1
            If detailErrorsShown < MAX_CONNECTOR_ERROR_DETAILS_PER_DIAGRAM Then
                ReportLine "    CONNECTOR ERROR " & CStr(connectorOrdinal) & ": " & _
                           CStr(connectorErrNumber) & " - " & CStr(connectorErrDescription)
                detailErrorsShown = detailErrorsShown + 1
            End If
        ElseIf Len(connectorPiece) > 0 Then
            If Not firstConnector Then connectorJson = connectorJson & "," & vbCrLf
            firstConnector = False
            connectorJson = connectorJson & connectorPiece
            gConnectorCount = gConnectorCount + 1
        End If
    Next

    ReportLine "  OBJECT CLASSIFICATION: semantic=" & CStr(diagramSemanticNodes) & _
               " [external=" & CStr(diagramExternalDafNodes) & "], graphical-only=" & _
               CStr(diagramGraphicalOnly) & ", semantic-gaps=" & CStr(diagramSemanticGaps) & _
               ", ambiguous=" & CStr(diagramAmbiguousObjects) & ", missing-EA=" & _
               CStr(diagramMissingEaObjects)

    If diagramConnectorErrors > 0 Then
        ReportLine "  CONNECTOR ERRORS ISOLATED: " & CStr(diagramConnectorErrors)
        gWarningCount = gWarningCount + 1
    End If
    If diagramRelationshipSkipped > 0 Then
        ReportLine "  CONNECTORS SKIPPED (not present in semantic relationship index): " & _
                   CStr(diagramRelationshipSkipped)
        gWarningCount = gWarningCount + 1
    End If
    If diagramEndpointSkipped > 0 Then
        ReportLine "  CONNECTORS SKIPPED (semantic endpoint not represented by a node): " & _
                   CStr(diagramEndpointSkipped)
    End If
    If diagramAmbiguousEndpointSkipped > 0 Then
        ReportLine "  CONNECTORS SKIPPED (ambiguous duplicate endpoint occurrence): " & _
                   CStr(diagramAmbiguousEndpointSkipped)
        gWarningCount = gWarningCount + 1
    End If
    If diagramSemanticGaps > 0 Or diagramAmbiguousObjects > 0 Or diagramMissingEaObjects > 0 Then
        gWarningCount = gWarningCount + 1
    End If

    If diagramSemanticNodes = 0 Then
        gDiagramSkippedNoSemanticCount = gDiagramSkippedNoSemanticCount + 1
        ReportLine "SKIPPED DIAGRAM: " & SafeStringValue(diagram.Name, "Unnamed diagram") & _
                   " | no exact DAF semantic node could be emitted"
        Exit Sub
    End If

    json = "{" & vbCrLf
    json = json & "  " & J("id") & ": " & J(viewId) & "," & vbCrLf
    json = json & "  " & J("name") & ": " & J(SafeStringValue(diagram.Name, "Unnamed diagram")) & "," & vbCrLf
    If Len(diagramDescription) > 0 Then
        json = json & "  " & J("description") & ": " & J(diagramDescription) & "," & vbCrLf
    Else
        json = json & "  " & J("description") & ": null," & vbCrLf
    End If
    json = json & "  " & J("viewpoint") & ": null," & vbCrLf
    json = json & "  " & J("nodes") & ": [" & vbCrLf & nodeJson & vbCrLf & "  ]," & vbCrLf
    json = json & "  " & J("connectors") & ": [" & vbCrLf & connectorJson & vbCrLf & "  ]," & vbCrLf
    json = json & "  " & J("canvas") & ": {" & _
                J("width") & ": " & N(canvasWidth) & ", " & _
                J("height") & ": " & N(canvasHeight) & ", " & _
                J("scale") & ": 1.0}," & vbCrLf
    json = json & "  " & J("metadata") & ": {" & vbCrLf
    json = json & "    " & J("source") & ": {" & vbCrLf
    json = json & "      " & J("kind") & ": " & J("imported") & "," & vbCrLf
    json = json & "      " & J("system") & ": " & J("Sparx Enterprise Architect") & "," & vbCrLf
    json = json & "      " & J("external_id") & ": " & J(SafeStringValue(diagram.DiagramGUID, "")) & vbCrLf
    json = json & "    }" & vbCrLf
    json = json & "  }" & vbCrLf
    json = json & "}" & vbCrLf

    outputPath = OUTPUT_FOLDER & "\" & _
                 SafeFileName(SafeStringValue(diagram.Name, "Unnamed diagram")) & "__" & diagramKey & ".view.json"
    WriteUtf8File outputPath, json

    gDiagramCount = gDiagramCount + 1
    ReportLine "EXPORTED: " & SafeStringValue(diagram.Name, "Unnamed diagram") & " -> " & outputPath
End Sub

Function BuildConnectorOccurrenceJson( _
    diagram, dlink, diagramKey, connectorOrdinal, _
    duidToNodeIds, elementIriToNodeIds, nodeIdToElementIri, _
    offsetX, offsetY, ByRef diagramEndpointSkipped, ByRef diagramRelationshipSkipped, _
    ByRef diagramAmbiguousEndpointSkipped)

    Dim connectorId, info
    Dim connectorGuid, connectorGuidKey
    Dim clientId, supplierId, directionText
    Dim sourceDuid, targetDuid
    Dim sourceNodeId, targetNodeId
    Dim relationshipIri
    Dim semanticSourceIri, semanticTargetIri
    Dim semanticRecord
    Dim endpointsSwapped
    Dim eaClientIri, eaSupplierIri
    Dim directScore, reverseScore
    Dim preferredSourceDuid, preferredTargetDuid
    Dim endpointAmbiguous
    Dim sourceAmbiguous, targetAmbiguous
    Dim points
    Dim routeKind, routeJson
    Dim json

    BuildConnectorOccurrenceJson = ""

    If SafeBoolValue(dlink.IsHidden, False) Then
        gHiddenConnectorCount = gHiddenConnectorCount + 1
        Exit Function
    End If

    connectorId = SafeLongValue(dlink.ConnectorID, 0)
    If connectorId <= 0 Then
        gMissingConnectorCount = gMissingConnectorCount + 1
        Exit Function
    End If

    info = GetConnectorInfo(connectorId)
    If Not SafeBoolValue(info(0), False) Then
        gMissingConnectorCount = gMissingConnectorCount + 1
        Exit Function
    End If

    connectorGuid = SafeStringValue(info(1), "")
    clientId = SafeLongValue(info(2), 0)
    supplierId = SafeLongValue(info(3), 0)
    directionText = SafeStringValue(info(4), "Unspecified")

    connectorGuidKey = NormalizeGuid(connectorGuid)
    If Len(connectorGuidKey) = 0 Then
        diagramRelationshipSkipped = diagramRelationshipSkipped + 1
        gUnresolvedRelationshipConnectorCount = gUnresolvedRelationshipConnectorCount + 1
        Exit Function
    End If

    If Not gSemanticRelByGuid.Exists(connectorGuidKey) Then
        diagramRelationshipSkipped = diagramRelationshipSkipped + 1
        gUnresolvedRelationshipConnectorCount = gUnresolvedRelationshipConnectorCount + 1
        Exit Function
    End If

    semanticRecord = gSemanticRelByGuid(connectorGuidKey)
    relationshipIri = SafeStringValue(semanticRecord(0), "")
    semanticSourceIri = SafeStringValue(semanticRecord(1), "")
    semanticTargetIri = SafeStringValue(semanticRecord(2), "")
    gSemanticRelationshipUsedCount = gSemanticRelationshipUsedCount + 1

    sourceDuid = NormalizeGuid(SafeStringValue(dlink.SourceInstanceUID, ""))
    targetDuid = NormalizeGuid(SafeStringValue(dlink.TargetInstanceUID, ""))

    ' Score the two possible display orientations by exact semantic identity.
    directScore = DuidSemanticMatchCount(sourceDuid, semanticSourceIri, duidToNodeIds, nodeIdToElementIri) + _
                  DuidSemanticMatchCount(targetDuid, semanticTargetIri, duidToNodeIds, nodeIdToElementIri)
    reverseScore = DuidSemanticMatchCount(sourceDuid, semanticTargetIri, duidToNodeIds, nodeIdToElementIri) + _
                   DuidSemanticMatchCount(targetDuid, semanticSourceIri, duidToNodeIds, nodeIdToElementIri)

    endpointsSwapped = False
    If reverseScore > directScore Then
        endpointsSwapped = True
    ElseIf reverseScore = directScore Then
        eaClientIri = ElementIriFromElementId(clientId)
        eaSupplierIri = ElementIriFromElementId(supplierId)
        If Len(eaClientIri) > 0 And Len(eaSupplierIri) > 0 Then
            If LCase(eaClientIri) = LCase(semanticTargetIri) And _
               LCase(eaSupplierIri) = LCase(semanticSourceIri) Then
                endpointsSwapped = True
            End If
        End If
    End If

    If endpointsSwapped Then
        preferredSourceDuid = targetDuid
        preferredTargetDuid = sourceDuid
    Else
        preferredSourceDuid = sourceDuid
        preferredTargetDuid = targetDuid
    End If

    sourceAmbiguous = False
    targetAmbiguous = False
    sourceNodeId = ResolveNodeByDuidAndSemanticIri( _
        preferredSourceDuid, semanticSourceIri, duidToNodeIds, nodeIdToElementIri, sourceAmbiguous)
    targetNodeId = ResolveNodeByDuidAndSemanticIri( _
        preferredTargetDuid, semanticTargetIri, duidToNodeIds, nodeIdToElementIri, targetAmbiguous)

    If Len(sourceNodeId) = 0 And Not sourceAmbiguous Then
        sourceNodeId = ResolveUniqueNodeForSemanticIri( _
            semanticSourceIri, elementIriToNodeIds, sourceAmbiguous)
        If Len(sourceNodeId) > 0 Then gEndpointFallbackCount = gEndpointFallbackCount + 1
    End If
    If Len(targetNodeId) = 0 And Not targetAmbiguous Then
        targetNodeId = ResolveUniqueNodeForSemanticIri( _
            semanticTargetIri, elementIriToNodeIds, targetAmbiguous)
        If Len(targetNodeId) > 0 Then gEndpointFallbackCount = gEndpointFallbackCount + 1
    End If

    endpointAmbiguous = sourceAmbiguous Or targetAmbiguous
    If endpointAmbiguous Then
        diagramAmbiguousEndpointSkipped = diagramAmbiguousEndpointSkipped + 1
        gAmbiguousEndpointConnectorCount = gAmbiguousEndpointConnectorCount + 1
        Exit Function
    End If

    If Len(sourceNodeId) = 0 Or Len(targetNodeId) = 0 Then
        diagramEndpointSkipped = diagramEndpointSkipped + 1
        gUnresolvedEndpointConnectorCount = gUnresolvedEndpointConnectorCount + 1
        Exit Function
    End If

    If sourceNodeId = targetNodeId And LCase(semanticSourceIri) <> LCase(semanticTargetIri) Then
        diagramEndpointSkipped = diagramEndpointSkipped + 1
        gUnresolvedEndpointConnectorCount = gUnresolvedEndpointConnectorCount + 1
        Exit Function
    End If

    Set points = ParseEaPathPoints(SafeStringValue(dlink.Path, ""))
    If endpointsSwapped Then Set points = ReversePointCollection(points)

    routeKind = RoutingKindFor(SafeLongValue(dlink.LineStyle, 2), points.Count)
    routeJson = BuildRoutingJson(routeKind, points, offsetX, offsetY)

    json = "    {" & vbCrLf
    json = json & "      " & J("id") & ": " & _
        J(VIEW_CONNECTOR_IRI_BASE & diagramKey & ":" & connectorGuidKey & ":" & CStr(connectorOrdinal)) & "," & vbCrLf
    json = json & "      " & J("relationship_id") & ": " & J(relationshipIri) & "," & vbCrLf
    json = json & "      " & J("source_node") & ": " & J(sourceNodeId) & "," & vbCrLf
    json = json & "      " & J("target_node") & ": " & J(targetNodeId) & "," & vbCrLf
    json = json & "      " & J("direction") & ": " & _
        J(MapConnectorDirectionWithSwap(directionText, endpointsSwapped)) & "," & vbCrLf
    json = json & "      " & J("routing") & ": " & routeJson & "," & vbCrLf
    json = json & "      " & J("z_index") & ": 0," & vbCrLf
    json = json & "      " & J("presentation") & ": " & _
        BuildConnectorPresentationJson(dlink) & "," & vbCrLf
    json = json & "      " & J("metadata") & ": " & _
        BuildConnectorOccurrenceMetadataJson(connectorId, connectorGuid) & vbCrLf
    json = json & "    }"

    If endpointsSwapped Then gSemanticEndpointReverseCount = gSemanticEndpointReverseCount + 1
    BuildConnectorOccurrenceJson = json
End Function

Function GetConnectorInfo(connectorId)
    Dim key, conn, result
    key = CStr(SafeLongValue(connectorId, 0))

    If gConnectorInfoById.Exists(key) Then
        gConnectorCacheHits = gConnectorCacheHits + 1
        GetConnectorInfo = gConnectorInfoById(key)
        Exit Function
    End If

    gConnectorCacheMisses = gConnectorCacheMisses + 1
    result = Array(False, "", 0, 0, "Unspecified")
    Set conn = Nothing

    On Error Resume Next
    Set conn = Repository.GetConnectorByID(SafeLongValue(connectorId, 0))
    If Err.Number = 0 And Not conn Is Nothing Then
        result = Array( _
            True, _
            SafeStringValue(conn.ConnectorGUID, ""), _
            SafeLongValue(conn.ClientID, 0), _
            SafeLongValue(conn.SupplierID, 0), _
            SafeStringValue(conn.Direction, "Unspecified"))
    End If
    Err.Clear
    On Error GoTo 0

    gConnectorInfoById(key) = result
    GetConnectorInfo = result
End Function

Function BuildNodeOccurrenceId(diagramKey, dobj, occurrenceBaseCount)
    Dim duid, baseKey, count, elementId

    duid = NormalizeGuid(SafeStringValue(dobj.InstanceGUID, ""))
    elementId = SafeLongValue(dobj.ElementID, 0)

    If Len(duid) > 0 Then
        baseKey = duid
    Else
        baseKey = "element-" & CStr(elementId)
    End If

    count = 1
    If occurrenceBaseCount.Exists(baseKey) Then
        count = SafeLongValue(occurrenceBaseCount(baseKey), 0) + 1
    End If
    occurrenceBaseCount(baseKey) = count

    If count > 1 Then
        If Len(duid) > 0 Then gDuplicateInstanceGuidOccurrenceCount = gDuplicateInstanceGuidOccurrenceCount + 1
        BuildNodeOccurrenceId = VIEW_NODE_IRI_BASE & diagramKey & ":" & baseKey & ":occurrence-" & CStr(count)
    Else
        BuildNodeOccurrenceId = VIEW_NODE_IRI_BASE & diagramKey & ":" & baseKey
    End If
End Function

Sub AddNodeReference(index, key, nodeId)
    Dim values
    If Len(SafeStringValue(key, "")) = 0 Then Exit Sub

    If index.Exists(key) Then
        Set values = index(key)
    Else
        Set values = CreateObject("Scripting.Dictionary")
        values.CompareMode = 1
        index.Add key, values
    End If
    values.Add CStr(values.Count), nodeId
End Sub

Function DuidSemanticMatchCount(duid, semanticIri, duidToNodeIds, nodeIdToElementIri)
    Dim values, i, nodeId, count
    count = 0

    If Len(duid) = 0 Or Len(semanticIri) = 0 Then
        DuidSemanticMatchCount = 0
        Exit Function
    End If
    If Not duidToNodeIds.Exists(duid) Then
        DuidSemanticMatchCount = 0
        Exit Function
    End If

    Set values = duidToNodeIds(duid)
    For i = 0 To values.Count - 1
        nodeId = SafeStringValue(values.Item(CStr(i)), "")
        If nodeIdToElementIri.Exists(nodeId) Then
            If LCase(SafeStringValue(nodeIdToElementIri(nodeId), "")) = LCase(semanticIri) Then
                count = count + 1
            End If
        End If
    Next

    DuidSemanticMatchCount = count
End Function

Function ResolveNodeByDuidAndSemanticIri( _
    duid, semanticIri, duidToNodeIds, nodeIdToElementIri, ByRef ambiguous)

    Dim values, i, nodeId, matchId, matchCount
    ResolveNodeByDuidAndSemanticIri = ""
    ambiguous = False
    matchId = ""
    matchCount = 0

    If Len(duid) = 0 Or Len(semanticIri) = 0 Then Exit Function
    If Not duidToNodeIds.Exists(duid) Then Exit Function

    Set values = duidToNodeIds(duid)
    For i = 0 To values.Count - 1
        nodeId = SafeStringValue(values.Item(CStr(i)), "")
        If nodeIdToElementIri.Exists(nodeId) Then
            If LCase(SafeStringValue(nodeIdToElementIri(nodeId), "")) = LCase(semanticIri) Then
                matchCount = matchCount + 1
                matchId = nodeId
            End If
        End If
    Next

    If matchCount = 1 Then
        ResolveNodeByDuidAndSemanticIri = matchId
    ElseIf matchCount > 1 Then
        ambiguous = True
    End If
End Function

Function ResolveUniqueNodeForSemanticIri(semanticIri, elementIriToNodeIds, ByRef ambiguous)
    Dim values
    ResolveUniqueNodeForSemanticIri = ""
    ambiguous = False

    If Len(semanticIri) = 0 Then Exit Function
    If Not elementIriToNodeIds.Exists(semanticIri) Then Exit Function

    Set values = elementIriToNodeIds(semanticIri)
    If values.Count = 1 Then
        ResolveUniqueNodeForSemanticIri = SafeStringValue(values.Item("0"), "")
    ElseIf values.Count > 1 Then
        ambiguous = True
    End If
End Function

Function ElementIriFromElementId(elementId)
    Dim resolution
    resolution = GetElementResolution(elementId)
    If SafeStringValue(resolution(ER_STATUS), "") = STATUS_RESOLVED Then
        ElementIriFromElementId = SafeStringValue(resolution(ER_IRI), "")
    Else
        ElementIriFromElementId = ""
    End If
End Function

Function GetElementResolution(elementId)
    Dim key, idValue
    Dim element
    Dim rawGuid, guidKey
    Dim elementName, elementType, metaType, stereotype, stereotypeEx, packageName
    Dim status, iri, isExternal, rdfTypes, reason
    Dim candidates, candidate
    Dim i, dafCount, matchingCount
    Dim chosen, matched
    Dim likelyDaf
    Dim result

    idValue = SafeLongValue(elementId, 0)
    key = CStr(idValue)

    If gElementResolutionById.Exists(key) Then
        gElementCacheHits = gElementCacheHits + 1
        GetElementResolution = gElementResolutionById(key)
        Exit Function
    End If

    gElementCacheMisses = gElementCacheMisses + 1
    Set element = Nothing

    If idValue > 0 Then
        On Error Resume Next
        Set element = Repository.GetElementByID(idValue)
        Err.Clear
        On Error GoTo 0
    End If

    If element Is Nothing Then
        result = Array(STATUS_MISSING_EA, "", "", "", "", "", "", "", "", "", False, "", _
                       "Repository.GetElementByID did not return an EA element")
        gElementResolutionById(key) = result
        GetElementResolution = result
        Exit Function
    End If

    rawGuid = SafeElementGuid(element)
    guidKey = NormalizeGuid(rawGuid)
    elementName = SafeElementName(element)
    elementType = SafeElementType(element)
    metaType = SafeElementMetaType(element)
    stereotype = SafeElementStereotype(element)
    stereotypeEx = SafeElementStereotypeEx(element)
    packageName = SafeElementPackageName(element)
    likelyDaf = IsLikelyDafElement(stereotype, stereotypeEx)

    status = ""
    iri = ""
    isExternal = False
    rdfTypes = ""
    reason = ""
    dafCount = 0
    matchingCount = 0

    If Len(guidKey) > 0 And gSemanticResourcesByGuid.Exists(guidKey) Then
        Set candidates = gSemanticResourcesByGuid(guidKey)
        For i = 0 To candidates.Count - 1
            candidate = candidates.Item(CStr(i))
            If Not SafeBoolValue(candidate(SR_IS_RELATIONSHIP), False) And _
               SafeBoolValue(candidate(SR_IS_DAF_ELEMENT), False) Then
                dafCount = dafCount + 1
                chosen = candidate
                If CandidateMatchesEaStereotype(candidate, stereotype, stereotypeEx) Then
                    matchingCount = matchingCount + 1
                    matched = candidate
                End If
            End If
        Next

        If matchingCount = 1 Then
            chosen = matched
            status = STATUS_RESOLVED
        ElseIf matchingCount > 1 Then
            status = STATUS_AMBIGUOUS
            reason = "EA GUID maps to multiple DAF resources matching the EA stereotype: " & _
                     CandidateIriSummary(candidates)
        ElseIf dafCount = 1 Then
            status = STATUS_RESOLVED
        ElseIf dafCount > 1 Then
            status = STATUS_AMBIGUOUS
            reason = "EA GUID maps to multiple DAF semantic resources: " & CandidateIriSummary(candidates)
        ElseIf likelyDaf Then
            status = STATUS_SEMANTIC_GAP
            reason = "EA GUID exists in Turtle only as non-DAF resource(s): " & CandidateIriSummary(candidates)
        Else
            status = STATUS_GRAPHICAL_ONLY
            reason = "EA GUID maps only to non-DAF resource(s): " & CandidateIriSummary(candidates)
        End If

        If status = STATUS_RESOLVED Then
            iri = SafeStringValue(chosen(SR_IRI), "")
            isExternal = SafeBoolValue(chosen(SR_IS_EXTERNAL), False)
            rdfTypes = SafeStringValue(chosen(SR_TYPES), "")
            reason = "Exact EA GUID resolved to authoritative Turtle subject"
        ElseIf Len(rdfTypes) = 0 Then
            rdfTypes = CandidateTypeSummary(candidates)
        End If
    ElseIf likelyDaf Then
        status = STATUS_SEMANTIC_GAP
        reason = "EA element appears to use a DAF stereotype but its GUID is absent from Turtle"
    Else
        status = STATUS_GRAPHICAL_ONLY
        reason = "EA object has no DAF semantic resource in Turtle"
    End If

    result = Array(status, iri, guidKey, rawGuid, elementName, elementType, metaType, _
                   stereotype, stereotypeEx, packageName, isExternal, rdfTypes, reason)
    gElementResolutionById(key) = result
    GetElementResolution = result
End Function

Function CandidateMatchesEaStereotype(candidate, stereotype, stereotypeEx)
    Dim types, parts, i, iri, localName
    CandidateMatchesEaStereotype = False
    types = SafeStringValue(candidate(SR_TYPES), "")
    parts = Split(types, "|")

    For i = 0 To UBound(parts)
        iri = Trim(SafeStringValue(parts(i), ""))
        If Len(iri) > 0 And LCase(Left(iri, Len(DAF_MODEL_NAMESPACE))) = LCase(DAF_MODEL_NAMESPACE) Then
            localName = Mid(iri, Len(DAF_MODEL_NAMESPACE) + 1)
            If LCase(Trim(stereotype)) = LCase(localName) Then
                CandidateMatchesEaStereotype = True
                Exit Function
            End If
            If InStr(1, LCase(stereotypeEx), LCase("::" & localName), vbTextCompare) > 0 Then
                CandidateMatchesEaStereotype = True
                Exit Function
            End If
        End If
    Next
End Function

Function IsLikelyDafElement(stereotype, stereotypeEx)
    Dim localStereo, fqStereo
    localStereo = LCase(Trim(SafeStringValue(stereotype, "")))
    fqStereo = LCase(Trim(SafeStringValue(stereotypeEx, "")))

    If Len(localStereo) > 0 And gKnownDafStereotypes.Exists(localStereo) Then
        IsLikelyDafElement = True
    ElseIf InStr(1, fqStereo, "daf::", vbTextCompare) > 0 Then
        IsLikelyDafElement = True
    ElseIf InStr(1, fqStereo, "daf 6.", vbTextCompare) > 0 Then
        IsLikelyDafElement = True
    ElseIf InStr(1, fqStereo, "digital architecture framework", vbTextCompare) > 0 Then
        IsLikelyDafElement = True
    Else
        IsLikelyDafElement = False
    End If
End Function

Function CandidateIriSummary(candidates)
    Dim i, candidate, text
    text = ""
    For i = 0 To candidates.Count - 1
        candidate = candidates.Item(CStr(i))
        If Len(text) > 0 Then text = text & " | "
        text = text & SafeStringValue(candidate(SR_IRI), "")
    Next
    CandidateIriSummary = text
End Function

Function CandidateTypeSummary(candidates)
    Dim i, candidate, text
    text = ""
    For i = 0 To candidates.Count - 1
        candidate = candidates.Item(CStr(i))
        If Len(text) > 0 Then text = text & " || "
        text = text & SafeStringValue(candidate(SR_TYPES), "")
    Next
    CandidateTypeSummary = text
End Function

Function BuildNodeOccurrenceMetadataJson(dobj, resolution)
    Dim externalId
    externalId = SafeStringValue(dobj.InstanceGUID, "")
    If Len(externalId) = 0 Then externalId = SafeStringValue(resolution(ER_RAW_GUID), "")

    BuildNodeOccurrenceMetadataJson = "{" & _
        J("external_id") & ": " & J(externalId) & ", " & _
        J("attributes") & ": {" & _
            J("ea_element_id") & ": " & J(CStr(SafeLongValue(dobj.ElementID, 0))) & ", " & _
            J("ea_element_guid") & ": " & J(SafeStringValue(resolution(ER_RAW_GUID), "")) & ", " & _
            J("ea_type") & ": " & J(SafeStringValue(resolution(ER_TYPE), "")) & ", " & _
            J("ea_meta_type") & ": " & J(SafeStringValue(resolution(ER_META_TYPE), "")) & ", " & _
            J("ea_stereotype") & ": " & J(SafeStringValue(resolution(ER_STEREOTYPE), "")) & ", " & _
            J("ea_stereotype_ex") & ": " & J(SafeStringValue(resolution(ER_STEREOTYPE_EX), "")) & ", " & _
            J("semantic_origin") & ": " & J(IIfText(SafeBoolValue(resolution(ER_IS_EXTERNAL), False), _
                                                       "external-daf-resource", "model-resource")) & _
        "}" & _
        "}"
End Function

Function BuildConnectorOccurrenceMetadataJson(connectorId, connectorGuid)
    BuildConnectorOccurrenceMetadataJson = "{" & _
        J("external_id") & ": " & J(SafeStringValue(connectorGuid, "")) & ", " & _
        J("attributes") & ": {" & _
            J("ea_connector_id") & ": " & J(CStr(SafeLongValue(connectorId, 0))) & ", " & _
            J("ea_connector_guid") & ": " & J(SafeStringValue(connectorGuid, "")) & _
        "}" & _
        "}"
End Function

Sub RecordSkippedObject(diagram, dobj, resolution, ByRef detailsShown)
    Dim status, reason
    status = SafeStringValue(resolution(ER_STATUS), STATUS_MISSING_EA)
    reason = SafeStringValue(resolution(ER_REASON), "")

    gSkippedObjectAudit = gSkippedObjectAudit & _
        Csv(status) & "," & _
        Csv(reason) & "," & _
        Csv(SafeStringValue(diagram.Name, "")) & "," & _
        Csv(SafeStringValue(diagram.DiagramGUID, "")) & "," & _
        Csv(CStr(SafeLongValue(dobj.ElementID, 0))) & "," & _
        Csv(SafeStringValue(resolution(ER_RAW_GUID), "")) & "," & _
        Csv(SafeStringValue(resolution(ER_NAME), "")) & "," & _
        Csv(SafeStringValue(resolution(ER_TYPE), "")) & "," & _
        Csv(SafeStringValue(resolution(ER_META_TYPE), "")) & "," & _
        Csv(SafeStringValue(resolution(ER_STEREOTYPE), "")) & "," & _
        Csv(SafeStringValue(resolution(ER_STEREOTYPE_EX), "")) & "," & _
        Csv(SafeStringValue(resolution(ER_PACKAGE), "")) & "," & _
        Csv(SafeStringValue(resolution(ER_IRI), "")) & "," & _
        Csv(SafeStringValue(resolution(ER_RDF_TYPES), "")) & vbCrLf

    If detailsShown < MAX_SKIPPED_OBJECT_DETAILS_PER_DIAGRAM Then
        ReportLine "    SKIP OBJECT [" & status & "]: " & _
                   SafeStringValue(resolution(ER_NAME), "<unnamed>") & _
                   " | GUID=" & SafeStringValue(resolution(ER_RAW_GUID), "") & _
                   " | type=" & SafeStringValue(resolution(ER_TYPE), "") & _
                   " | stereotype=" & SafeStringValue(resolution(ER_STEREOTYPE), "") & _
                   " | " & reason
        detailsShown = detailsShown + 1
    End If
End Sub

Function BuildNodePresentationJson(dobj, stereotypeVisible)
    Dim json
    Dim rectangleNotation
    Dim style
    Dim showComposed

    style = SafeDiagramObjectStyle(dobj)
    rectangleNotation = StyleFlag(style, "UCRect", "1")
    showComposed = SafeBoolValue(dobj.ShowComposedDiagram, False)

    json = "{" & _
        J("label_visible") & ": true, " & _
        J("stereotype_visible") & ": " & B(SafeBoolValue(stereotypeVisible, True)) & ", " & _
        J("collapsed") & ": false, " & _
        J("rectangle_notation") & ": " & B(rectangleNotation) & ", " & _
        J("is_composite") & ": " & B(showComposed) & ", " & _
        J("style_overrides") & ": " & BuildNodeStyleOverridesJson(dobj) & _
        "}"

    BuildNodePresentationJson = json
End Function

Function BuildNodeStyleOverridesJson(dobj)
    Dim fillJson, lineJson, textJson, widthJson
    Dim borderWidth

    fillJson = ColorJsonOrNull(SafeLongValue(dobj.BackgroundColor, -1))
    lineJson = ColorJsonOrNull(SafeLongValue(dobj.BorderColor, -1))
    textJson = ColorJsonOrNull(SafeLongValue(dobj.FontColor, -1))

    borderWidth = SafeLongValue(dobj.BorderLineWidth, 1)
    If borderWidth > 1 Then
        widthJson = N(borderWidth)
    Else
        widthJson = "null"
    End If

    BuildNodeStyleOverridesJson = "{" & _
        J("fill_color") & ": " & fillJson & ", " & _
        J("line_color") & ": " & lineJson & ", " & _
        J("text_color") & ": " & textJson & ", " & _
        J("line_width") & ": " & widthJson & _
        "}"
End Function

Function BuildConnectorPresentationJson(dlink)
    Dim labelsVisible
    Dim lineJson, widthJson
    Dim lineWidth

    labelsVisible = Not SafeBoolValue(dlink.HiddenLabels, False)
    lineJson = ColorJsonOrNull(SafeLongValue(dlink.LineColor, -1))
    lineWidth = SafeLongValue(dlink.LineWidth, 0)

    If lineWidth > 0 Then
        widthJson = N(lineWidth)
    Else
        widthJson = "null"
    End If

    BuildConnectorPresentationJson = "{" & _
        J("label_visible") & ": " & B(labelsVisible) & ", " & _
        J("source_label_visible") & ": " & B(labelsVisible) & ", " & _
        J("target_label_visible") & ": " & B(labelsVisible) & ", " & _
        J("style_overrides") & ": {" & _
            J("line_color") & ": " & lineJson & ", " & _
            J("text_color") & ": null, " & _
            J("line_width") & ": " & widthJson & _
        "}" & _
        "}"
End Function

Function MapConnectorDirection(directionText)
    Dim v
    v = LCase(Trim(SafeStringValue(directionText, "Unspecified")))

    Select Case v
        Case "source -> destination", "source to destination"
            MapConnectorDirection = "source-to-destination"
        Case "destination -> source", "destination to source"
            MapConnectorDirection = "destination-to-source"
        Case "bi-directional", "bidirectional"
            MapConnectorDirection = "bi-directional"
        Case Else
            MapConnectorDirection = "unspecified"
    End Select
End Function

Function MapConnectorDirectionWithSwap(directionText, endpointsSwapped)
    Dim mapped
    mapped = MapConnectorDirection(directionText)

    If CBool(endpointsSwapped) Then
        If mapped = "source-to-destination" Then
            mapped = "destination-to-source"
        ElseIf mapped = "destination-to-source" Then
            mapped = "source-to-destination"
        End If
    End If

    MapConnectorDirectionWithSwap = mapped
End Function

Function NodeRepresents(nodeId, elementIri, nodeIdToElementIri)
    If nodeIdToElementIri.Exists(nodeId) Then
        NodeRepresents = (LCase(CStr(nodeIdToElementIri(nodeId))) = LCase(CStr(elementIri)))
    Else
        NodeRepresents = False
    End If
End Function

Function RoutingKindFor(lineStyle, pointCount)
    Dim styleValue
    styleValue = SafeLongValue(lineStyle, 2)

    Select Case styleValue
        Case 1
            RoutingKindFor = "straight"
        Case 2
            RoutingKindFor = "auto"
        Case 3
            If SafeLongValue(pointCount, 0) > 0 Then
                RoutingKindFor = "polyline"
            Else
                RoutingKindFor = "auto"
            End If
        Case 4, 5, 6, 7, 8, 9
            If SafeLongValue(pointCount, 0) > 0 Then
                RoutingKindFor = "orthogonal"
            ElseIf styleValue = 8 Or styleValue = 9 Then
                RoutingKindFor = "orthogonal"
            Else
                RoutingKindFor = "auto"
            End If
        Case Else
            RoutingKindFor = "auto"
    End Select
End Function

Function BuildRoutingJson(kind, points, offsetX, offsetY)
    Dim json, firstPoint, pt, i

    Select Case kind
        Case "straight"
            BuildRoutingJson = "{" & J("kind") & ": " & J("straight") & "}"
            Exit Function
        Case "auto"
            BuildRoutingJson = "{" & J("kind") & ": " & J("auto") & "}"
            Exit Function
    End Select

    json = "{" & J("kind") & ": " & J(kind) & ", " & J("waypoints") & ": ["
    firstPoint = True
    For i = 0 To points.Count - 1
        pt = points.Item(CStr(i))
        If Not firstPoint Then json = json & ", "
        firstPoint = False
        json = json & "{" & _
            J("x") & ": " & N(SafeDoubleValue(pt(0), 0) + SafeDoubleValue(offsetX, 0)) & ", " & _
            J("y") & ": " & N(SafeDoubleValue(pt(1), 0) + SafeDoubleValue(offsetY, 0)) & _
            "}"
    Next
    json = json & "]}"

    BuildRoutingJson = json
End Function

Function ParseEaPathPoints(pathText)
    Dim points
    Dim matches, match
    Dim x, rawY
    Dim sourceText

    Set points = CreateObject("Scripting.Dictionary")
    sourceText = SafeStringValue(pathText, "")

    If Len(Trim(sourceText)) = 0 Then
        Set ParseEaPathPoints = points
        Exit Function
    End If

    Set matches = gPathPointRegex.Execute(sourceText)
    For Each match In matches
        x = SafeDoubleValue(match.SubMatches(0), 0)
        rawY = SafeDoubleValue(match.SubMatches(2), 0)

        ' EA diagram Y values are negative below the origin; Dafrion uses normal
        ' logical coordinates, so invert the EA Y axis here.
        points.Add CStr(points.Count), Array(x, -rawY)
    Next

    Set ParseEaPathPoints = points
End Function

Function ReversePointCollection(points)
    Dim reversed
    Dim i
    Set reversed = CreateObject("Scripting.Dictionary")
    For i = points.Count - 1 To 0 Step -1
        reversed.Add CStr(reversed.Count), points.Item(CStr(i))
    Next
    Set ReversePointCollection = reversed
End Function

Function StyleFlag(styleText, key, expectedValue)
    Dim token
    token = LCase(key & "=" & expectedValue)
    StyleFlag = (InStr(1, LCase(SafeStringValue(styleText, "")), token, vbTextCompare) > 0)
End Function

Function DiagramStyleFlag(styleText, key, expectedValue)
    DiagramStyleFlag = StyleFlag(styleText, key, expectedValue)
End Function

Function ColorJsonOrNull(colorValue)
    Dim r, g, b, value
    value = SafeLongValue(colorValue, -1)

    If value < 0 Then
        ColorJsonOrNull = "null"
        Exit Function
    End If

    r = value And 255
    g = (value \ 256) And 255
    b = (value \ 65536) And 255

    ColorJsonOrNull = "{" & _
        J("r") & ": " & CStr(r) & ", " & _
        J("g") & ": " & CStr(g) & ", " & _
        J("b") & ": " & CStr(b) & ", " & _
        J("a") & ": 255}"
End Function

Sub UpdateExtent(ByVal px, ByVal py, ByRef haveExtent, ByRef minX, ByRef minY, ByRef maxX, ByRef maxY)
    Dim x, y
    x = SafeDoubleValue(px, 0)
    y = SafeDoubleValue(py, 0)

    If Not SafeBoolValue(haveExtent, False) Then
        minX = x
        minY = y
        maxX = x
        maxY = y
        haveExtent = True
    Else
        If x < minX Then minX = x
        If y < minY Then minY = y
        If x > maxX Then maxX = x
        If y > maxY Then maxY = y
    End If
End Sub

Function ResolveSemanticTtlPath()
    Dim folder, file, newestPath, newestDate
    Dim lowerName

    If gFso.FileExists(SEMANTIC_TTL_PATH) Then
        ResolveSemanticTtlPath = SEMANTIC_TTL_PATH
        Exit Function
    End If

    newestPath = ""
    newestDate = #1/1/1900#

    On Error Resume Next
    If gFso.FolderExists("C:\tmp") Then
        Set folder = gFso.GetFolder("C:\tmp")
        For Each file In folder.Files
            lowerName = LCase(file.Name)
            If LCase(gFso.GetExtensionName(file.Name)) = "ttl" And _
               InStr(1, lowerName, "eurocom", vbTextCompare) > 0 Then
                If file.DateLastModified > newestDate Then
                    newestDate = file.DateLastModified
                    newestPath = file.Path
                End If
            End If
        Next
    End If
    Err.Clear
    On Error GoTo 0

    ResolveSemanticTtlPath = newestPath
End Function

Sub LoadSemanticModelIndex(ttlPath)
    Const AD_READ_LINE = -2
    Const PROGRESS_EVERY_LINES = 5000

    Dim stream
    Dim line, trimmed
    Dim prefixes
    Dim currentSubject, currentBlock
    Dim lineCount, statementCount, resourceCandidateCount, relationshipCandidateCount
    Dim fileSize, fileSizeMb

    Set prefixes = CreateObject("Scripting.Dictionary")
    prefixes.CompareMode = 1

    lineCount = 0
    statementCount = 0
    resourceCandidateCount = 0
    relationshipCandidateCount = 0
    currentSubject = ""
    currentBlock = ""

    fileSize = 0
    On Error Resume Next
    fileSize = CDbl(gFso.GetFile(ttlPath).Size)
    Err.Clear
    On Error GoTo 0
    fileSizeMb = fileSize / 1048576
    ProgressLine "  Semantic TTL size: " & FormatNumber(fileSizeMb, 2) & " MB"
    ProgressLine "  Opening semantic TTL..."

    On Error Resume Next
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 2
    stream.Charset = "utf-8"
    stream.Open
    stream.LoadFromFile ttlPath
    If Err.Number <> 0 Then
        ReportLine "ERROR: Could not open semantic Turtle model: " & CStr(Err.Number) & " - " & CStr(Err.Description)
        gWarningCount = gWarningCount + 1
        Err.Clear
        If Not stream Is Nothing Then stream.Close
        Set stream = Nothing
        On Error GoTo 0
        Exit Sub
    End If
    On Error GoTo 0

    ProgressLine "  Parsing semantic TTL..."

    Do Until stream.EOS
        line = stream.ReadText(AD_READ_LINE)
        lineCount = lineCount + 1

        If lineCount = 1 Then
            If Len(line) > 0 Then
                If AscW(Left(line, 1)) = &HFEFF Then line = Mid(line, 2)
            End If
        End If

        line = Replace(CStr(line), vbCr, "")
        trimmed = Trim(line)

        If currentSubject = "" And Left(trimmed, 7) = "@prefix" Then
            RegisterTurtlePrefix trimmed, prefixes
        ElseIf trimmed = "" Or Left(trimmed, 1) = "#" Then
            ' Ignore comments and blank lines.
        Else
            If currentSubject = "" Then
                currentSubject = FirstTurtleToken(trimmed)
                currentBlock = line & vbLf
            Else
                currentBlock = currentBlock & line & vbLf
            End If

            If Right(trimmed, 1) = "." Then
                statementCount = statementCount + 1

                If ContainsTurtlePredicate(currentBlock, "dafm:eaGuid") Then
                    resourceCandidateCount = resourceCandidateCount + 1
                    IndexSemanticResourceBlock currentSubject, currentBlock, prefixes
                End If

                If ContainsTurtlePredicate(currentBlock, "dafm:source") And _
                   ContainsTurtlePredicate(currentBlock, "dafm:target") Then
                    relationshipCandidateCount = relationshipCandidateCount + 1
                    IndexSemanticRelationshipBlock currentSubject, currentBlock, prefixes
                End If

                currentSubject = ""
                currentBlock = ""
            End If
        End If

        If (lineCount Mod PROGRESS_EVERY_LINES) = 0 Then
            ProgressLine "  TTL progress: " & CStr(lineCount) & " lines, " & _
                         CStr(statementCount) & " statements, " & _
                         CStr(gSemanticResourceCount) & " resources, " & _
                         CStr(gSemanticRelationshipCount) & " relationships indexed"
        End If
    Loop

    stream.Close
    Set stream = Nothing

    ProgressLine "  TTL parse complete: " & CStr(lineCount) & " lines, " & _
                 CStr(statementCount) & " statements, " & _
                 CStr(resourceCandidateCount) & " GUID-bearing candidates, " & _
                 CStr(relationshipCandidateCount) & " relationship candidates"
    ProgressLine "  Indexed resources: " & CStr(gSemanticResourceCount)
    ProgressLine "  Indexed relationships: " & CStr(gSemanticRelationshipCount)
End Sub

Sub RegisterTurtlePrefix(line, prefixes)
    Dim s, colonPos, ltPos, gtPos
    Dim prefixName, baseIri

    s = Trim(SafeStringValue(line, ""))
    colonPos = InStr(1, s, ":", vbBinaryCompare)
    ltPos = InStr(1, s, "<", vbBinaryCompare)
    gtPos = InStr(ltPos + 1, s, ">", vbBinaryCompare)

    If colonPos <= 8 Or ltPos <= colonPos Or gtPos <= ltPos Then Exit Sub

    prefixName = Trim(Mid(s, 8, colonPos - 8))
    baseIri = Mid(s, ltPos + 1, gtPos - ltPos - 1)

    If Len(prefixName) > 0 And Len(baseIri) > 0 Then
        prefixes(prefixName) = baseIri
    End If
End Sub

Sub IndexSemanticResourceBlock(subjectToken, blockText, prefixes)
    Dim resourceIri, guidKey, types
    Dim isDafElement, isExternal, isPackage, isRelationship
    Dim record, candidates
    Dim dafCandidateCount

    guidKey = ExtractEaGuidKey(blockText)
    If Len(guidKey) = 0 Then Exit Sub

    resourceIri = ExpandTurtleToken(subjectToken, prefixes)
    If Len(resourceIri) = 0 Then Exit Sub

    types = ExtractRdfTypeIris(blockText, prefixes)
    isDafElement = TypeListContainsNamespace(types, DAF_MODEL_NAMESPACE)
    isExternal = TypeListContainsIri(types, DAF_INSTANCE_NAMESPACE & "ExternalElement")
    isPackage = TypeListContainsIri(types, DAF_INSTANCE_NAMESPACE & "Package")
    isRelationship = TypeListContainsIri(types, DAF_METAMODEL_NAMESPACE & "Relationship") Or _
                     (ContainsTurtlePredicate(blockText, "dafm:source") And _
                      ContainsTurtlePredicate(blockText, "dafm:target"))

    record = Array(resourceIri, isDafElement, isExternal, isPackage, isRelationship, types)

    If gSemanticResourcesByGuid.Exists(guidKey) Then
        Set candidates = gSemanticResourcesByGuid(guidKey)
    Else
        Set candidates = CreateObject("Scripting.Dictionary")
        candidates.CompareMode = 1
        gSemanticResourcesByGuid.Add guidKey, candidates
    End If

    If CandidateIriExists(candidates, resourceIri) Then Exit Sub

    If candidates.Count > 0 And Not gSemanticCollisionGuids.Exists(guidKey) Then
        gSemanticCollisionGuids.Add guidKey, True
        gSemanticGuidCollisionCount = gSemanticGuidCollisionCount + 1
    End If

    candidates.Add CStr(candidates.Count), record
    gSemanticResourceCount = gSemanticResourceCount + 1

    If isDafElement Then
        gSemanticDafElementCount = gSemanticDafElementCount + 1
        RegisterKnownDafTypes types
    End If
    If isExternal Then gSemanticExternalResourceCount = gSemanticExternalResourceCount + 1
    If isExternal And isDafElement Then
        gSemanticExternalDafElementCount = gSemanticExternalDafElementCount + 1
    End If
    If isPackage Then gSemanticPackageResourceCount = gSemanticPackageResourceCount + 1

    dafCandidateCount = CountDafElementCandidates(candidates)
    If dafCandidateCount > 1 And Not gSemanticAmbiguousDafGuids.Exists(guidKey) Then
        gSemanticAmbiguousDafGuids.Add guidKey, True
        gSemanticAmbiguousDafGuidCount = gSemanticAmbiguousDafGuidCount + 1
    End If
End Sub

Function CandidateIriExists(candidates, resourceIri)
    Dim i, candidate
    CandidateIriExists = False
    For i = 0 To candidates.Count - 1
        candidate = candidates.Item(CStr(i))
        If LCase(SafeStringValue(candidate(SR_IRI), "")) = LCase(resourceIri) Then
            CandidateIriExists = True
            Exit Function
        End If
    Next
End Function

Function CountDafElementCandidates(candidates)
    Dim i, candidate, count
    count = 0
    For i = 0 To candidates.Count - 1
        candidate = candidates.Item(CStr(i))
        If SafeBoolValue(candidate(SR_IS_DAF_ELEMENT), False) And _
           Not SafeBoolValue(candidate(SR_IS_RELATIONSHIP), False) Then
            count = count + 1
        End If
    Next
    CountDafElementCandidates = count
End Function

Function ExtractRdfTypeIris(blockText, prefixes)
    Dim normalized, lines, line
    Dim i, trimmed, collecting, typeText, semiPos
    Dim tokens, token, iri, result

    normalized = Replace(SafeStringValue(blockText, ""), vbCr, "")
    lines = Split(normalized, vbLf)
    collecting = False
    typeText = ""

    For i = 0 To UBound(lines)
        trimmed = Trim(SafeStringValue(lines(i), ""))
        If Not collecting Then
            If LCase(Left(trimmed, 2)) = "a " Then
                typeText = Mid(trimmed, 3)
                collecting = True
            ElseIf LCase(Left(trimmed, 9)) = "rdf:type " Then
                typeText = Mid(trimmed, 10)
                collecting = True
            End If
        Else
            typeText = typeText & " " & trimmed
        End If

        If collecting Then
            semiPos = InStr(1, typeText, ";", vbBinaryCompare)
            If semiPos > 0 Then
                typeText = Left(typeText, semiPos - 1)
                Exit For
            End If
        End If
    Next

    result = ""
    If Len(Trim(typeText)) > 0 Then
        tokens = Split(typeText, ",")
        For Each token In tokens
            iri = ExpandTurtleToken(CleanTurtleToken(token), prefixes)
            If Len(iri) > 0 Then
                If InStr(1, "|" & LCase(result) & "|", "|" & LCase(iri) & "|", vbBinaryCompare) = 0 Then
                    If Len(result) > 0 Then result = result & "|"
                    result = result & iri
                End If
            End If
        Next
    End If

    ExtractRdfTypeIris = result
End Function

Function TypeListContainsNamespace(types, namespaceIri)
    Dim parts, i, iri
    TypeListContainsNamespace = False
    parts = Split(SafeStringValue(types, ""), "|")
    For i = 0 To UBound(parts)
        iri = Trim(SafeStringValue(parts(i), ""))
        If Len(iri) >= Len(namespaceIri) Then
            If LCase(Left(iri, Len(namespaceIri))) = LCase(namespaceIri) Then
                TypeListContainsNamespace = True
                Exit Function
            End If
        End If
    Next
End Function

Function TypeListContainsIri(types, expectedIri)
    Dim parts, i
    TypeListContainsIri = False
    parts = Split(SafeStringValue(types, ""), "|")
    For i = 0 To UBound(parts)
        If LCase(Trim(SafeStringValue(parts(i), ""))) = LCase(expectedIri) Then
            TypeListContainsIri = True
            Exit Function
        End If
    Next
End Function

Sub RegisterKnownDafTypes(types)
    Dim parts, i, iri, localName
    parts = Split(SafeStringValue(types, ""), "|")
    For i = 0 To UBound(parts)
        iri = Trim(SafeStringValue(parts(i), ""))
        If Len(iri) >= Len(DAF_MODEL_NAMESPACE) Then
            If LCase(Left(iri, Len(DAF_MODEL_NAMESPACE))) = LCase(DAF_MODEL_NAMESPACE) Then
                localName = LCase(Mid(iri, Len(DAF_MODEL_NAMESPACE) + 1))
                If Len(localName) > 0 Then
                    If Not gKnownDafStereotypes.Exists(localName) Then
                        gKnownDafStereotypes.Add localName, True
                    End If
                End If
            End If
        End If
    Next
End Sub

Sub IndexSemanticRelationshipBlock(subjectToken, blockText, prefixes)
    Dim sourceToken, targetToken, relationshipIri
    Dim sourceIri, targetIri, guidKey
    Dim record

    sourceToken = ExtractPredicateObject(blockText, "dafm:source")
    targetToken = ExtractPredicateObject(blockText, "dafm:target")

    If Len(sourceToken) = 0 Or Len(targetToken) = 0 Then Exit Sub

    relationshipIri = ExpandTurtleToken(subjectToken, prefixes)
    sourceIri = ExpandTurtleToken(sourceToken, prefixes)
    targetIri = ExpandTurtleToken(targetToken, prefixes)

    If Len(relationshipIri) = 0 Or Len(sourceIri) = 0 Or Len(targetIri) = 0 Then Exit Sub

    guidKey = ExtractEaGuidKey(blockText)
    If Len(guidKey) = 0 Then guidKey = ExtractGuidKeyFromIri(relationshipIri)
    If Len(guidKey) = 0 Then Exit Sub

    record = Array(relationshipIri, sourceIri, targetIri)
    If Not gSemanticRelByGuid.Exists(guidKey) Then
        gSemanticRelByGuid.Add guidKey, record
        gSemanticRelationshipCount = gSemanticRelationshipCount + 1
    End If
End Sub

Function ContainsTurtlePredicate(blockText, predicateToken)
    ContainsTurtlePredicate = (FindTurtlePredicatePosition(blockText, predicateToken) > 0)
End Function

Function FindTurtlePredicatePosition(blockText, predicateToken)
    Dim s, token, p, nextPos, ch
    s = SafeStringValue(blockText, "")
    token = SafeStringValue(predicateToken, "")
    p = 1

    Do
        p = InStr(p, s, token, vbTextCompare)
        If p = 0 Then
            FindTurtlePredicatePosition = 0
            Exit Function
        End If

        nextPos = p + Len(token)
        If nextPos > Len(s) Then
            FindTurtlePredicatePosition = p
            Exit Function
        End If

        ch = Mid(s, nextPos, 1)
        If ch = " " Or ch = vbTab Or ch = vbCr Or ch = vbLf Then
            FindTurtlePredicatePosition = p
            Exit Function
        End If

        p = nextPos
    Loop
End Function

Function ExtractPredicateObject(blockText, predicateToken)
    Dim s, p, i, ch, startPos
    s = SafeStringValue(blockText, "")
    p = FindTurtlePredicatePosition(s, predicateToken)

    If p = 0 Then
        ExtractPredicateObject = ""
        Exit Function
    End If

    i = p + Len(predicateToken)
    Do While i <= Len(s)
        ch = Mid(s, i, 1)
        If ch <> " " And ch <> vbTab And ch <> vbCr And ch <> vbLf Then Exit Do
        i = i + 1
    Loop

    startPos = i
    Do While i <= Len(s)
        ch = Mid(s, i, 1)
        If ch = " " Or ch = vbTab Or ch = vbCr Or ch = vbLf Or ch = ";" Then Exit Do
        i = i + 1
    Loop

    If i > startPos Then
        ExtractPredicateObject = CleanTurtleToken(Mid(s, startPos, i - startPos))
    Else
        ExtractPredicateObject = ""
    End If
End Function

Function FirstTurtleToken(line)
    Dim s, pSpace, pTab, p
    s = Trim(SafeStringValue(line, ""))

    pSpace = InStr(1, s, " ", vbBinaryCompare)
    pTab = InStr(1, s, vbTab, vbBinaryCompare)

    If pSpace = 0 Then
        p = pTab
    ElseIf pTab = 0 Then
        p = pSpace
    ElseIf pSpace < pTab Then
        p = pSpace
    Else
        p = pTab
    End If

    If p > 0 Then
        FirstTurtleToken = CleanTurtleToken(Left(s, p - 1))
    Else
        FirstTurtleToken = CleanTurtleToken(s)
    End If
End Function

Function CleanTurtleToken(token)
    Dim s
    s = Trim(CStr(token))
    Do While Len(s) > 0 And (Right(s, 1) = ";" Or Right(s, 1) = "," Or Right(s, 1) = ".")
        s = Left(s, Len(s) - 1)
    Loop
    CleanTurtleToken = s
End Function

Function ExpandTurtleToken(token, prefixes)
    Dim s, p, localName, colonPos
    s = CleanTurtleToken(token)

    If Len(s) >= 2 And Left(s, 1) = "<" And Right(s, 1) = ">" Then
        ExpandTurtleToken = Mid(s, 2, Len(s) - 2)
        Exit Function
    End If

    colonPos = InStr(1, s, ":", vbBinaryCompare)
    If colonPos > 1 Then
        p = Left(s, colonPos - 1)
        localName = Mid(s, colonPos + 1)
        If prefixes.Exists(p) Then
            ExpandTurtleToken = CStr(prefixes(p)) & localName
            Exit Function
        End If
    End If

    ExpandTurtleToken = ""
End Function

Function ExtractEaGuidKey(blockText)
    Dim s, p, q1, q2, raw
    s = SafeStringValue(blockText, "")
    p = InStr(1, s, "dafm:eaGuid", vbTextCompare)
    If p = 0 Then
        ExtractEaGuidKey = ""
        Exit Function
    End If

    q1 = InStr(p, s, Chr(34), vbBinaryCompare)
    If q1 = 0 Then
        ExtractEaGuidKey = ""
        Exit Function
    End If
    q2 = InStr(q1 + 1, s, Chr(34), vbBinaryCompare)
    If q2 = 0 Then
        ExtractEaGuidKey = ""
        Exit Function
    End If

    raw = Mid(s, q1 + 1, q2 - q1 - 1)
    ExtractEaGuidKey = NormalizeGuid(raw)
End Function

Function ExtractGuidKeyFromIri(iri)
    Dim matches, raw
    Set matches = gGuidInIriRegex.Execute(SafeStringValue(iri, ""))
    If matches.Count > 0 Then
        raw = SafeStringValue(matches(0).SubMatches(0), "")
        ExtractGuidKeyFromIri = NormalizeGuid(raw)
    Else
        ExtractGuidKeyFromIri = ""
    End If
End Function

Function ReadUtf8File(filePath)
    Dim stream
    On Error Resume Next
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 2
    stream.Charset = "utf-8"
    stream.Open
    stream.LoadFromFile filePath
    ReadUtf8File = stream.ReadText
    stream.Close
    Set stream = Nothing
    If Err.Number <> 0 Then
        Err.Clear
        ReadUtf8File = ""
    End If
    On Error GoTo 0
End Function

Function SafeElementGuid(element)
    On Error Resume Next
    SafeElementGuid = CStr(element.ElementGUID)
    If Err.Number <> 0 Then
        Err.Clear
        SafeElementGuid = ""
    End If
    On Error GoTo 0
End Function

Function SafeElementName(element)
    On Error Resume Next
    SafeElementName = CStr(element.Name)
    If Err.Number <> 0 Then
        Err.Clear
        SafeElementName = ""
    End If
    On Error GoTo 0
End Function

Function SafeElementType(element)
    On Error Resume Next
    SafeElementType = CStr(element.Type)
    If Err.Number <> 0 Then
        Err.Clear
        SafeElementType = ""
    End If
    On Error GoTo 0
End Function

Function SafeElementMetaType(element)
    On Error Resume Next
    SafeElementMetaType = CStr(element.MetaType)
    If Err.Number <> 0 Then
        Err.Clear
        SafeElementMetaType = ""
    End If
    On Error GoTo 0
End Function

Function SafeElementStereotype(element)
    On Error Resume Next
    SafeElementStereotype = CStr(element.Stereotype)
    If Err.Number <> 0 Then
        Err.Clear
        SafeElementStereotype = ""
    End If
    On Error GoTo 0
End Function

Function SafeElementStereotypeEx(element)
    On Error Resume Next
    SafeElementStereotypeEx = CStr(element.StereotypeEx)
    If Err.Number <> 0 Then
        Err.Clear
        SafeElementStereotypeEx = ""
    End If
    On Error GoTo 0
End Function

Function SafeElementPackageName(element)
    Dim packageId, pkg
    SafeElementPackageName = ""
    packageId = 0
    Set pkg = Nothing

    On Error Resume Next
    packageId = CLng(element.PackageID)
    If Err.Number <> 0 Then
        Err.Clear
        packageId = 0
    End If
    If packageId > 0 Then Set pkg = Repository.GetPackageByID(packageId)
    If Err.Number = 0 And Not pkg Is Nothing Then SafeElementPackageName = CStr(pkg.Name)
    Err.Clear
    On Error GoTo 0
End Function

Function SafeStringValue(value, defaultValue)
    Dim result
    result = SafeStringDefault(defaultValue)

    On Error Resume Next
    If IsObject(value) Or IsArray(value) Or IsNull(value) Or IsEmpty(value) Then
        SafeStringValue = result
    Else
        SafeStringValue = CStr(value)
        If Err.Number <> 0 Then
            Err.Clear
            SafeStringValue = result
        End If
    End If
    On Error GoTo 0
End Function

Function SafeStringDefault(value)
    On Error Resume Next
    If IsObject(value) Or IsArray(value) Or IsNull(value) Or IsEmpty(value) Then
        SafeStringDefault = ""
    Else
        SafeStringDefault = CStr(value)
        If Err.Number <> 0 Then
            Err.Clear
            SafeStringDefault = ""
        End If
    End If
    On Error GoTo 0
End Function

Function SafeLongValue(value, defaultValue)
    Dim result
    result = 0
    On Error Resume Next
    If IsNumeric(defaultValue) Then result = CLng(defaultValue)
    Err.Clear

    If Not IsObject(value) And Not IsArray(value) And Not IsNull(value) And Not IsEmpty(value) Then
        If IsNumeric(value) Then
            SafeLongValue = CLng(value)
            If Err.Number = 0 Then
                On Error GoTo 0
                Exit Function
            End If
        End If
    End If

    Err.Clear
    SafeLongValue = result
    On Error GoTo 0
End Function

Function SafeDoubleValue(value, defaultValue)
    Dim result
    result = 0
    On Error Resume Next
    If IsNumeric(defaultValue) Then result = CDbl(defaultValue)
    Err.Clear

    If Not IsObject(value) And Not IsArray(value) And Not IsNull(value) And Not IsEmpty(value) Then
        If IsNumeric(value) Then
            SafeDoubleValue = CDbl(value)
            If Err.Number = 0 Then
                On Error GoTo 0
                Exit Function
            End If
        End If
    End If

    Err.Clear
    SafeDoubleValue = result
    On Error GoTo 0
End Function

Function SafeBoolValue(value, defaultValue)
    Dim result, s
    result = False
    On Error Resume Next
    result = CBool(defaultValue)
    If Err.Number <> 0 Then
        Err.Clear
        result = False
    End If

    If IsObject(value) Or IsArray(value) Or IsNull(value) Or IsEmpty(value) Then
        SafeBoolValue = result
        On Error GoTo 0
        Exit Function
    End If

    If VarType(value) = 11 Then
        SafeBoolValue = CBool(value)
        If Err.Number = 0 Then
            On Error GoTo 0
            Exit Function
        End If
        Err.Clear
    End If

    If IsNumeric(value) Then
        SafeBoolValue = (CDbl(value) <> 0)
        If Err.Number = 0 Then
            On Error GoTo 0
            Exit Function
        End If
        Err.Clear
    End If

    s = LCase(Trim(SafeStringValue(value, "")))
    Select Case s
        Case "true", "yes", "y", "on"
            SafeBoolValue = True
        Case "false", "no", "n", "off", ""
            SafeBoolValue = False
        Case Else
            SafeBoolValue = result
    End Select
    On Error GoTo 0
End Function

Function SafeDiagramExtendedStyle(diagram)
    On Error Resume Next
    SafeDiagramExtendedStyle = CStr(diagram.ExtendedStyle)
    If Err.Number <> 0 Then
        Err.Clear
        SafeDiagramExtendedStyle = ""
    End If
    On Error GoTo 0
End Function

Function SafeDiagramObjectStyle(dobj)
    On Error Resume Next
    SafeDiagramObjectStyle = CStr(dobj.Style)
    If Err.Number <> 0 Then
        Err.Clear
        SafeDiagramObjectStyle = ""
    End If
    On Error GoTo 0
End Function

Function SafeDiagramNotes(diagram)
    On Error Resume Next
    SafeDiagramNotes = Trim(CStr(diagram.Notes))
    If Err.Number <> 0 Then
        Err.Clear
        SafeDiagramNotes = ""
    End If
    On Error GoTo 0
End Function

Function NormalizeGuid(value)
    Dim s
    s = LCase(Trim(SafeStringValue(value, "")))
    s = Replace(s, "{", "")
    s = Replace(s, "}", "")
    s = Replace(s, "-", "_")
    s = Replace(s, " ", "")
    NormalizeGuid = s
End Function

Function SafeFileName(value)
    Dim s, invalidChars, ch
    s = Trim(SafeStringValue(value, ""))
    If Len(s) = 0 Then s = "unnamed-diagram"

    invalidChars = Array("\", "/", ":", "*", "?", Chr(34), "<", ">", "|")
    For Each ch In invalidChars
        s = Replace(s, ch, "_")
    Next

    SafeFileName = s
End Function

Function J(value)
    Dim s, bs, dq
    bs = Chr(92)
    dq = Chr(34)
    s = SafeStringValue(value, "")
    s = Replace(s, bs, bs & bs)
    s = Replace(s, dq, bs & dq)
    s = Replace(s, vbCrLf, bs & "n")
    s = Replace(s, vbCr, bs & "n")
    s = Replace(s, vbLf, bs & "n")
    s = Replace(s, vbTab, bs & "t")
    J = dq & s & dq
End Function

Function N(value)
    Dim numberValue, textValue
    numberValue = SafeDoubleValue(value, 0)
    textValue = CStr(numberValue)
    textValue = Replace(textValue, ",", ".")
    N = textValue
End Function

Function B(value)
    If SafeBoolValue(value, False) Then
        B = "true"
    Else
        B = "false"
    End If
End Function

Function MinNumber(a, b)
    Dim av, bv
    av = SafeDoubleValue(a, 0)
    bv = SafeDoubleValue(b, 0)
    If av < bv Then
        MinNumber = av
    Else
        MinNumber = bv
    End If
End Function

Sub CleanPreviousExportFiles(folderPath)
    Dim folder, file, paths, pathValue, lowerName, pathIndex
    Set paths = CreateObject("Scripting.Dictionary")
    paths.CompareMode = 1

    On Error Resume Next
    If gFso.FolderExists(folderPath) Then
        Set folder = gFso.GetFolder(folderPath)
        For Each file In folder.Files
            lowerName = LCase(file.Name)
            If Right(lowerName, 10) = ".view.json" Or _
               lowerName = LCase(REPORT_FILE) Or _
               lowerName = LCase(SKIPPED_OBJECT_AUDIT_FILE) Then
                paths.Add CStr(paths.Count), file.Path
            End If
        Next
    End If
    Err.Clear
    On Error GoTo 0

    For pathIndex = 0 To paths.Count - 1
        pathValue = paths.Item(CStr(pathIndex))
        On Error Resume Next
        gFso.DeleteFile CStr(pathValue), True
        Err.Clear
        On Error GoTo 0
    Next
End Sub

Function Csv(value)
    Dim s
    s = SafeStringValue(value, "")
    s = Replace(s, vbCrLf, " ")
    s = Replace(s, vbCr, " ")
    s = Replace(s, vbLf, " ")
    s = Replace(s, Chr(34), Chr(34) & Chr(34))
    Csv = Chr(34) & s & Chr(34)
End Function

Function IIfText(condition, trueValue, falseValue)
    If SafeBoolValue(condition, False) Then
        IIfText = SafeStringValue(trueValue, "")
    Else
        IIfText = SafeStringValue(falseValue, "")
    End If
End Function

Sub Warn(diagram, message)
    gWarningCount = gWarningCount + 1
    ReportLine "WARNING [" & CStr(diagram.Name) & "]: " & message
End Sub

Sub ProgressLine(text)
    Session.Output FormatProgressTimestamp(Now) & " " & CStr(text)
End Sub

Sub ReportLine(text)
    Dim line
    line = CStr(text)
    gReport = gReport & line & vbCrLf
    Session.Output FormatProgressTimestamp(Now) & " " & line
End Sub

Function FormatProgressTimestamp(value)
    FormatProgressTimestamp = Right("0" & CStr(Hour(value)), 2) & ":" & _
                              Right("0" & CStr(Minute(value)), 2) & ":" & _
                              Right("0" & CStr(Second(value)), 2)
End Function

Sub EnsureFolder(folderPath)
    Dim parentPath

    If gFso.FolderExists(folderPath) Then Exit Sub

    parentPath = gFso.GetParentFolderName(folderPath)
    If Len(parentPath) > 0 And Not gFso.FolderExists(parentPath) Then
        EnsureFolder parentPath
    End If

    gFso.CreateFolder folderPath
End Sub

Sub WriteUtf8File(filePath, text)
    Dim stream
    Dim payload

    ' ADODB.Stream emits an UTF-8 BOM in text mode. Strip those first three
    ' bytes so serde_json receives ordinary UTF-8 JSON.
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 2
    stream.Charset = "utf-8"
    stream.Open
    stream.WriteText CStr(text)

    stream.Position = 0
    stream.Type = 1
    If stream.Size >= 3 Then
        stream.Position = 3
        payload = stream.Read
        stream.Position = 0
        stream.SetEOS
        stream.Write payload
    End If

    stream.SaveToFile filePath, 2
    stream.Close
    Set stream = Nothing
End Sub

Main
