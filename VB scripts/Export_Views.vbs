Option Explicit

' ============================================================================
' EuroCom -> Dafrion View Exporter
' Target: Sparx Enterprise Architect internal VBScript engine
' Dafrion view contract: crates/dafrion-view
' DAF version: 6.3
' ============================================================================

Const SCRIPT_VERSION = "0.1.4"
Const ROOT_PACKAGE_GUID = "{2B098F05-3CC7-4637-9A68-0DAD07564747}"
Const MODEL_IRI_BASE = "urn:daf:model:2b098f05-3cc7-4637-9a68-0dad07564747#"
Const ELEMENT_IRI_PREFIX = "element_"

' IMPORTANT:
' This must match the first-class relationship resource naming convention used
' by the existing EuroCom M1 RDF exporter. The exact prefix is intentionally
' isolated here because it is not defined by dafrion-view itself.
Const RELATIONSHIP_IRI_PREFIX = "relationship_"

' Preferred semantic model produced by the existing EuroCom M1 exporter.
' When present, this file is indexed to obtain the exact first-class relationship
' IRI and authoritative dafm:source/dafm:target endpoints.
Const SEMANTIC_TTL_PATH = "C:\Users\broth\Documents\work\ATAK\src\Dafrion\models\reference\eurocom\eurocom.ttl"

Const VIEW_IRI_BASE = "urn:dafrion:view:eurocom:"
Const VIEW_NODE_IRI_BASE = "urn:dafrion:view-node:eurocom:"
Const VIEW_CONNECTOR_IRI_BASE = "urn:dafrion:view-connector:eurocom:"

Const OUTPUT_FOLDER = "C:\tmp\Dafrion-EuroCom-views"
Const REPORT_FILE = "EuroCom-view-export.report.txt"
Const MARGIN = 20
Const MIN_NODE_SIZE = 1
Const MAX_CONNECTOR_ERROR_DETAILS_PER_DIAGRAM = 5

Dim gFso
Dim gDiagramCount
Dim gNodeCount
Dim gConnectorCount
Dim gHiddenConnectorCount
Dim gMissingConnectorCount
Dim gEndpointFallbackCount
Dim gInvalidBoundsCount
Dim gWarningCount
Dim gReport
Dim gSemanticRelByGuid
Dim gSemanticTtlResolvedPath
Dim gSemanticRelationshipCount
Dim gSemanticRelationshipUsedCount
Dim gSemanticRelationshipFallbackCount
Dim gSemanticEndpointReverseCount
Dim gElementIriById
Dim gConnectorInfoById
Dim gElementCacheHits
Dim gElementCacheMisses
Dim gConnectorCacheHits
Dim gConnectorCacheMisses
Dim gConnectorRuntimeErrorCount
Dim gUnresolvedEndpointConnectorCount
Dim gPathPointRegex
Dim gGuidInIriRegex

Sub Main()
    Dim rootPackage

    Set gFso = CreateObject("Scripting.FileSystemObject")
    Set gSemanticRelByGuid = CreateObject("Scripting.Dictionary")
    gSemanticRelByGuid.CompareMode = 1
    Set gElementIriById = CreateObject("Scripting.Dictionary")
    Set gConnectorInfoById = CreateObject("Scripting.Dictionary")
    gElementIriById.CompareMode = 1
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
    gNodeCount = 0
    gConnectorCount = 0
    gHiddenConnectorCount = 0
    gMissingConnectorCount = 0
    gEndpointFallbackCount = 0
    gInvalidBoundsCount = 0
    gWarningCount = 0
    gSemanticRelationshipCount = 0
    gSemanticRelationshipUsedCount = 0
    gSemanticRelationshipFallbackCount = 0
    gSemanticEndpointReverseCount = 0
    gElementCacheHits = 0
    gElementCacheMisses = 0
    gConnectorCacheHits = 0
    gConnectorCacheMisses = 0
    gConnectorRuntimeErrorCount = 0
    gUnresolvedEndpointConnectorCount = 0
    gSemanticTtlResolvedPath = ""
    gReport = ""

    EnsureFolder OUTPUT_FOLDER

    Session.Output ""
    Session.Output "=== Dafrion EuroCom View Exporter " & SCRIPT_VERSION & " ==="
    ReportLine "DAFRION EUROCOM VIEW EXPORT REPORT"
    ReportLine "Generated: " & CStr(Now)
    ReportLine "Exporter version: " & SCRIPT_VERSION
    ReportLine "DAF framework version: 6.3"
    ReportLine "Root package GUID: " & ROOT_PACKAGE_GUID
    ReportLine "Output folder: " & OUTPUT_FOLDER
    ReportLine "Relationship fallback IRI prefix: " & RELATIONSHIP_IRI_PREFIX
    ReportLine "Preferred semantic model: " & SEMANTIC_TTL_PATH
    ReportLine ""

    gSemanticTtlResolvedPath = ResolveSemanticTtlPath()
    If Len(gSemanticTtlResolvedPath) > 0 Then
        ReportLine "Semantic model resolved: " & gSemanticTtlResolvedPath
        ReportLine "Indexing semantic relationships..."
        LoadSemanticRelationshipIndex gSemanticTtlResolvedPath
        ReportLine "Semantic relationship authority: " & gSemanticTtlResolvedPath
        ReportLine "Indexed first-class relationships: " & CStr(gSemanticRelationshipCount)
        If gSemanticRelationshipCount = 0 Then
            ReportLine "WARNING: Turtle file was read but no dafm:source/dafm:target relationship instances were indexed."
            gWarningCount = gWarningCount + 1
        End If
    Else
        ReportLine "WARNING: Semantic Turtle model not found; connector identities and endpoint order will use EA fallbacks."
        gWarningCount = gWarningCount + 1
    End If
    ReportLine ""

    On Error Resume Next
    Set rootPackage = Repository.GetPackageByGuid(ROOT_PACKAGE_GUID)
    If Err.Number <> 0 Or rootPackage Is Nothing Then
        ReportLine "ERROR: Cannot resolve root package " & ROOT_PACKAGE_GUID
        ReportLine "EA error: " & Err.Description
        Err.Clear
        On Error GoTo 0
        WriteUtf8File OUTPUT_FOLDER & "\" & REPORT_FILE, gReport
        Exit Sub
    End If
    On Error GoTo 0

    ReportLine "Root package: " & rootPackage.Name
    ReportLine ""

    ExportPackageRecursive rootPackage

    ReportLine ""
    ReportLine "SUMMARY"
    ReportLine "Diagrams exported: " & CStr(gDiagramCount)
    ReportLine "Node occurrences exported: " & CStr(gNodeCount)
    ReportLine "Visible connector occurrences exported: " & CStr(gConnectorCount)
    ReportLine "Hidden connector occurrences skipped: " & CStr(gHiddenConnectorCount)
    ReportLine "Diagram links with missing semantic connector skipped: " & CStr(gMissingConnectorCount)
    ReportLine "Connector endpoint occurrence fallbacks: " & CStr(gEndpointFallbackCount)
    ReportLine "Invalid/zero node bounds clamped: " & CStr(gInvalidBoundsCount)
    ReportLine "Semantic first-class relationships indexed: " & CStr(gSemanticRelationshipCount)
    ReportLine "Connector occurrences resolved from semantic authority: " & CStr(gSemanticRelationshipUsedCount)
    ReportLine "Connector occurrences using fallback relationship IRI/order: " & CStr(gSemanticRelationshipFallbackCount)
    ReportLine "Graphical endpoint orders reversed to match semantic source/target: " & CStr(gSemanticEndpointReverseCount)
    ReportLine "Connector occurrences skipped for unresolved endpoints: " & CStr(gUnresolvedEndpointConnectorCount)
    ReportLine "Connector runtime errors isolated: " & CStr(gConnectorRuntimeErrorCount)
    ReportLine "Element metadata cache: " & CStr(gElementCacheHits) & " hits / " & CStr(gElementCacheMisses) & " misses"
    ReportLine "Connector metadata cache: " & CStr(gConnectorCacheHits) & " hits / " & CStr(gConnectorCacheMisses) & " misses"
    ReportLine "Warnings: " & CStr(gWarningCount)
    ReportLine ""
    ReportLine "NOTES"
    ReportLine "- Each JSON file is serialized to the current dafrion-view View structure."
    ReportLine "- Semantic element data is never copied into a view; nodes reference element IRIs only."
    ReportLine "- Hidden EA DiagramLinks are not exported because ViewConnector represents a visible occurrence."
    ReportLine "- EA connector custom Path coordinates are preserved when parseable."
    ReportLine "- Rectangle notation is read from UCRect in the diagram-object style when present."
    ReportLine "- When the M1 Turtle file is available, relationship identity and dafm:source/dafm:target"
    ReportLine "  are authoritative and graphical endpoints are reordered to match them."
    ReportLine "- RELATIONSHIP_IRI_PREFIX and EA Client/Supplier order are used only when a connector"
    ReportLine "  cannot be resolved from the M1 Turtle relationship index."
    ReportLine "- EA COM values are converted defensively; one malformed connector cannot abort an entire diagram."
    ReportLine "- Element and connector metadata are cached across diagrams to reduce Repository COM calls."
    ReportLine "- SourceInstanceUID/TargetInstanceUID and DiagramObject InstanceGUID are normalized before matching."

    ReportLine "Export finished. Report: " & OUTPUT_FOLDER & "\" & REPORT_FILE
    WriteUtf8File OUTPUT_FOLDER & "\" & REPORT_FILE, gReport
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
    Dim duidToNodeId
    Dim elementIdToNodeId
    Dim elementIdToNodeCount
    Dim ordinalToNodeId
    Dim elementIriToNodeId
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
    Dim diagramConnectorErrors, diagramEndpointSkipped
    Dim detailErrorsShown
    Dim zIndex

    Set duidToNodeId = CreateObject("Scripting.Dictionary")
    Set elementIdToNodeId = CreateObject("Scripting.Dictionary")
    Set elementIdToNodeCount = CreateObject("Scripting.Dictionary")
    Set ordinalToNodeId = CreateObject("Scripting.Dictionary")
    Set elementIriToNodeId = CreateObject("Scripting.Dictionary")
    Set nodeIdToElementIri = CreateObject("Scripting.Dictionary")
    duidToNodeId.CompareMode = 1
    elementIriToNodeId.CompareMode = 1
    nodeIdToElementIri.CompareMode = 1

    minX = 0
    minY = 0
    maxX = 0
    maxY = 0
    haveExtent = False
    diagramConnectorErrors = 0
    diagramEndpointSkipped = 0
    detailErrorsShown = 0

    diagramKey = NormalizeGuid(SafeStringValue(diagram.DiagramGUID, ""))
    If Len(diagramKey) = 0 Then diagramKey = "diagram_" & CStr(SafeLongValue(diagram.DiagramID, 0))
    viewId = VIEW_IRI_BASE & diagramKey

    ' Pass 1: collect node occurrence identities and total extents.
    pass1NodeOrdinal = 0
    For Each dobj In diagram.DiagramObjects
        pass1NodeOrdinal = pass1NodeOrdinal + 1

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

        elementId = SafeLongValue(dobj.ElementID, 0)
        nodeId = BuildNodeOccurrenceId(diagramKey, dobj, elementIdToNodeCount)
        elementIri = ElementIriFromElementId(elementId)

        ordinalToNodeId(CStr(pass1NodeOrdinal)) = nodeId
        nodeIdToElementIri(nodeId) = elementIri

        duid = NormalizeGuid(SafeStringValue(dobj.InstanceGUID, ""))
        If Len(duid) > 0 Then duidToNodeId(duid) = nodeId

        If elementId > 0 Then
            If Not elementIdToNodeId.Exists(CStr(elementId)) Then
                elementIdToNodeId(CStr(elementId)) = nodeId
            End If
        End If
        If Not elementIriToNodeId.Exists(elementIri) Then
            elementIriToNodeId(elementIri) = nodeId
        End If
    Next

    ' Pass 1b: include custom connector route points in the logical extents.
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

    ' Pass 2: serialize nodes with rebased logical coordinates.
    nodeOrdinal = 0
    For Each dobj In diagram.DiagramObjects
        nodeOrdinal = nodeOrdinal + 1

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

        If ordinalToNodeId.Exists(CStr(nodeOrdinal)) Then
            nodeId = ordinalToNodeId(CStr(nodeOrdinal))
        Else
            nodeId = ResolveNodeIdForObject(diagramKey, dobj, duidToNodeId, elementIdToNodeId)
        End If

        If nodeIdToElementIri.Exists(nodeId) Then
            elementIri = nodeIdToElementIri(nodeId)
        Else
            elementIri = ElementIriFromElementId(elementId)
        End If

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
                   BuildNodePresentationJson(dobj, stereotypeVisible) & vbCrLf
        nodeJson = nodeJson & "    }"

        gNodeCount = gNodeCount + 1
    Next

    connectorJson = ""
    firstConnector = True
    connectorOrdinal = 0

    ' Pass 3: serialize each DiagramLink independently. Unexpected COM variants on
    ' one connector are isolated here and cannot abort the complete diagram.
    For Each dlink In diagram.DiagramLinks
        connectorOrdinal = connectorOrdinal + 1
        connectorPiece = ""
        connectorErrNumber = 0
        connectorErrDescription = ""

        On Error Resume Next
        connectorPiece = BuildConnectorOccurrenceJson( _
            diagram, dlink, diagramKey, connectorOrdinal, _
            duidToNodeId, elementIdToNodeId, elementIriToNodeId, nodeIdToElementIri, _
            offsetX, offsetY, diagramEndpointSkipped)
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

    If diagramConnectorErrors > 0 Then
        ReportLine "  CONNECTOR ERRORS ISOLATED: " & CStr(diagramConnectorErrors)
        gWarningCount = gWarningCount + 1
    End If
    If diagramEndpointSkipped > 0 Then
        ReportLine "  CONNECTORS SKIPPED (no visible endpoint occurrence): " & CStr(diagramEndpointSkipped)
        gWarningCount = gWarningCount + 1
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
    duidToNodeId, elementIdToNodeId, elementIriToNodeId, nodeIdToElementIri, _
    offsetX, offsetY, ByRef diagramEndpointSkipped)

    Dim connectorId, info
    Dim connectorGuid, connectorGuidKey
    Dim clientId, supplierId, directionText
    Dim sourceDuid, targetDuid
    Dim eaSourceNodeId, eaTargetNodeId
    Dim sourceNodeId, targetNodeId
    Dim relationshipIri
    Dim semanticSourceIri, semanticTargetIri
    Dim semanticRecord
    Dim endpointsSwapped
    Dim eaClientIri, eaSupplierIri
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
    If Len(connectorGuidKey) = 0 Then connectorGuidKey = "eaid_" & CStr(connectorId)

    sourceDuid = NormalizeGuid(SafeStringValue(dlink.SourceInstanceUID, ""))
    targetDuid = NormalizeGuid(SafeStringValue(dlink.TargetInstanceUID, ""))

    eaSourceNodeId = ""
    eaTargetNodeId = ""
    sourceNodeId = ""
    targetNodeId = ""
    relationshipIri = ""
    semanticSourceIri = ""
    semanticTargetIri = ""
    endpointsSwapped = False

    If Len(sourceDuid) > 0 And duidToNodeId.Exists(sourceDuid) Then
        eaSourceNodeId = duidToNodeId(sourceDuid)
    End If
    If Len(targetDuid) > 0 And duidToNodeId.Exists(targetDuid) Then
        eaTargetNodeId = duidToNodeId(targetDuid)
    End If

    If gSemanticRelByGuid.Exists(connectorGuidKey) Then
        semanticRecord = gSemanticRelByGuid(connectorGuidKey)
        relationshipIri = SafeStringValue(semanticRecord(0), "")
        semanticSourceIri = SafeStringValue(semanticRecord(1), "")
        semanticTargetIri = SafeStringValue(semanticRecord(2), "")
        gSemanticRelationshipUsedCount = gSemanticRelationshipUsedCount + 1

        ' Determine source/target orientation even when EA occurrence UIDs are absent.
        eaClientIri = ElementIriFromElementId(clientId)
        eaSupplierIri = ElementIriFromElementId(supplierId)
        If LCase(eaClientIri) = LCase(semanticTargetIri) And _
           LCase(eaSupplierIri) = LCase(semanticSourceIri) Then
            endpointsSwapped = True
        End If

        ' Exact occurrence UIDs are preferred because one semantic element may occur
        ' more than once in the same diagram.
        If Len(eaSourceNodeId) > 0 And Len(eaTargetNodeId) > 0 Then
            If NodeRepresents(eaSourceNodeId, semanticSourceIri, nodeIdToElementIri) And _
               NodeRepresents(eaTargetNodeId, semanticTargetIri, nodeIdToElementIri) Then
                sourceNodeId = eaSourceNodeId
                targetNodeId = eaTargetNodeId
                endpointsSwapped = False
            ElseIf NodeRepresents(eaSourceNodeId, semanticTargetIri, nodeIdToElementIri) And _
                   NodeRepresents(eaTargetNodeId, semanticSourceIri, nodeIdToElementIri) Then
                sourceNodeId = eaTargetNodeId
                targetNodeId = eaSourceNodeId
                endpointsSwapped = True
            End If
        End If

        If Len(sourceNodeId) = 0 And elementIriToNodeId.Exists(semanticSourceIri) Then
            sourceNodeId = elementIriToNodeId(semanticSourceIri)
            gEndpointFallbackCount = gEndpointFallbackCount + 1
        End If
        If Len(targetNodeId) = 0 And elementIriToNodeId.Exists(semanticTargetIri) Then
            targetNodeId = elementIriToNodeId(semanticTargetIri)
            gEndpointFallbackCount = gEndpointFallbackCount + 1
        End If

        If endpointsSwapped Then gSemanticEndpointReverseCount = gSemanticEndpointReverseCount + 1
    Else
        gSemanticRelationshipFallbackCount = gSemanticRelationshipFallbackCount + 1
        relationshipIri = RelationshipIri(connectorGuidKey)

        sourceNodeId = eaSourceNodeId
        targetNodeId = eaTargetNodeId

        If Len(sourceNodeId) = 0 And clientId > 0 Then
            If elementIdToNodeId.Exists(CStr(clientId)) Then
                sourceNodeId = elementIdToNodeId(CStr(clientId))
                gEndpointFallbackCount = gEndpointFallbackCount + 1
            End If
        End If
        If Len(targetNodeId) = 0 And supplierId > 0 Then
            If elementIdToNodeId.Exists(CStr(supplierId)) Then
                targetNodeId = elementIdToNodeId(CStr(supplierId))
                gEndpointFallbackCount = gEndpointFallbackCount + 1
            End If
        End If
    End If

    If Len(sourceNodeId) = 0 Or Len(targetNodeId) = 0 Then
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
        BuildConnectorPresentationJson(dlink) & vbCrLf
    json = json & "    }"

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

Function BuildNodeOccurrenceId(diagramKey, dobj, elementIdToNodeCount)
    Dim duid, elementKey, count, elementId

    duid = NormalizeGuid(SafeStringValue(dobj.InstanceGUID, ""))
    If Len(duid) > 0 Then
        BuildNodeOccurrenceId = VIEW_NODE_IRI_BASE & diagramKey & ":" & duid
        Exit Function
    End If

    elementId = SafeLongValue(dobj.ElementID, 0)
    elementKey = CStr(elementId)
    count = 1
    If elementIdToNodeCount.Exists(elementKey) Then
        count = SafeLongValue(elementIdToNodeCount(elementKey), 0) + 1
    End If
    elementIdToNodeCount(elementKey) = count

    BuildNodeOccurrenceId = VIEW_NODE_IRI_BASE & diagramKey & ":element-" & elementKey & ":" & CStr(count)
End Function

Function ResolveNodeIdForObject(diagramKey, dobj, duidToNodeId, elementIdToNodeId)
    Dim duid, elementId
    duid = NormalizeGuid(SafeStringValue(dobj.InstanceGUID, ""))
    elementId = SafeLongValue(dobj.ElementID, 0)

    If Len(duid) > 0 And duidToNodeId.Exists(duid) Then
        ResolveNodeIdForObject = duidToNodeId(duid)
    ElseIf elementIdToNodeId.Exists(CStr(elementId)) Then
        ResolveNodeIdForObject = elementIdToNodeId(CStr(elementId))
    Else
        ResolveNodeIdForObject = VIEW_NODE_IRI_BASE & diagramKey & ":element-" & CStr(elementId)
    End If
End Function

Function ElementIriFromElementId(elementId)
    Dim element
    Dim key, idValue, iri

    idValue = SafeLongValue(elementId, 0)
    key = CStr(idValue)

    If gElementIriById.Exists(key) Then
        gElementCacheHits = gElementCacheHits + 1
        ElementIriFromElementId = gElementIriById(key)
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
        iri = MODEL_IRI_BASE & ELEMENT_IRI_PREFIX & "eaid_" & key
    Else
        iri = MODEL_IRI_BASE & ELEMENT_IRI_PREFIX & NormalizeGuid(SafeStringValue(element.ElementGUID, ""))
    End If

    gElementIriById(key) = iri
    ElementIriFromElementId = iri
End Function

Function RelationshipIri(connectorGuid)
    Dim key
    key = NormalizeGuid(SafeStringValue(connectorGuid, ""))
    If Len(key) = 0 Then key = "unknown"
    RelationshipIri = MODEL_IRI_BASE & RELATIONSHIP_IRI_PREFIX & key
End Function

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
            If LCase(gFso.GetExtensionName(file.Name)) = "ttl" And _
               InStr(1, LCase(file.Name), "daf-eurocom", vbTextCompare) > 0 Then
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

Sub LoadSemanticRelationshipIndex(ttlPath)
    Const AD_READ_LINE = -2
    Const PROGRESS_EVERY_LINES = 5000

    Dim stream
    Dim line, trimmed
    Dim prefixes
    Dim currentSubject, currentBlock
    Dim lineCount, statementCount, candidateCount
    Dim fileSize, fileSizeMb

    Set prefixes = CreateObject("Scripting.Dictionary")
    prefixes.CompareMode = 1

    lineCount = 0
    statementCount = 0
    candidateCount = 0
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

        ' ADODB.Stream may expose the UTF-8 BOM on the first line.
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

                ' Most Turtle statements are not first-class relationships. Avoid
                ' creating expensive VBScript.RegExp COM objects for them.
                If ContainsTurtlePredicate(currentBlock, "dafm:source") And _
                   ContainsTurtlePredicate(currentBlock, "dafm:target") Then
                    candidateCount = candidateCount + 1
                    IndexSemanticRelationshipBlock currentSubject, currentBlock, prefixes
                End If

                currentSubject = ""
                currentBlock = ""
            End If
        End If

        If (lineCount Mod PROGRESS_EVERY_LINES) = 0 Then
            ProgressLine "  TTL progress: " & CStr(lineCount) & " lines, " & _
                         CStr(statementCount) & " statements, " & _
                         CStr(gSemanticRelationshipCount) & " relationships indexed"
        End If
    Loop

    stream.Close
    Set stream = Nothing

    ProgressLine "  TTL parse complete: " & CStr(lineCount) & " lines, " & _
                 CStr(statementCount) & " statements, " & _
                 CStr(candidateCount) & " relationship candidates"
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
