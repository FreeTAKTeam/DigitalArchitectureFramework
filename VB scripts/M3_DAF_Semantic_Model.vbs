Option Explicit
'
' Script Name: M3 Generate DAF RDF Semantic Model
' Author: Giu Platania / generated with ChatGPT assistance
' Purpose:
'   Transform the authoritative DAF M3/M2 metamodel in Enterprise Architect into
'   a technology-independent RDF/OWL/SHACL semantic metamodel.
'
'   The generated Turtle file contains:
'     - DAF meta-metamodel vocabulary
'     - vendor-neutral common ModelElement metadata
'     - all DAF Concepts
'     - all M3 attributes as semantic property definitions
'     - all Enumerations and values
'     - inheritance/generalization
'     - all DAF relationships as first-class relationship types
'     - projected OWL object properties and inverse properties
'     - source/target relationship-end semantics
'     - multiplicities/cardinalities
'     - aggregation/composition, navigability, containment and role information
'     - all available tagged values
'     - available element/attribute/connector constraints
'     - SHACL shapes for common fields, attributes and relationships
'     - EA package/source provenance for traceability
'
' Design:
'   This script intentionally does NOT generate OpenAPI. The RDF/SHACL model is
'   intended to become the authoritative DAF M2 semantic definition. OpenAPI,
'   Rust types, JSON Schema and documentation should later be generated from it.
'
' Source orientation:
'   DAF M3 relationships use EA connector ClientID as the semantic source and
'   SupplierID as the semantic target, matching the existing DAF UML Profile /
'   QuickLink generator. SupplierEnd.Role is the forward meaning; ClientEnd.Role
'   is the backward meaning.
'
' Version: 1.3.1
' Date: 2026 / 08 / 07
'
' 1.3.1 relationship filtering:
'   - ignores EA NoteLink connectors because they are diagram/documentation links, not DAF semantic relationships
'   - excludes NoteLink connectors from registration, RDF export, completeness reconciliation and warning counts
'   - reports the number of ignored NoteLink connectors for auditability
'
' 1.3.0 completeness changes:
'   - registers and exports supporting M3 classes, not only DAF Concepts
'   - preserves relationships whose endpoints are supporting M3 classes
'   - reconciles generated UML Profile mappings by Metamodel GUID
'   - uses collision-safe GUID-based property-definition identities
'   - keeps readable property predicates while disambiguating duplicate names
'   - records how each relationship kind was determined
'   - uses human-readable aliases as RDF labels and internal names as notation
'   - fails the completeness audit when a registered M3 class or relationship disappears
'
' Requirements:
'   - Run inside Sparx Enterprise Architect
'   - Uses the existing shared script configuration from DAF MDG.DAF M3 Conf
'   - Does not introduce a second set of package GUIDs or filesystem paths
'
' Output:
'   <TechFilePath>\rdf\<ProfileName>-semantic-model.ttl
'   <TechFilePath>\rdf\<ProfileName>-semantic-model-report.txt
'
' The shared configuration remains authoritative for:
'   metamodelPackageGUID, profilePackageGUID, relationshipPackageGUID,
'   quickLinkFileName, ProfileName, mdgTechFilePath, TechFilePath,
'   ProfileDiagramGUID, UMLProfileFilename, ProfileToolboxClassGUID,
'   ProfileToolboxConnectorGUID, IconPath, SQLPath, CSVPath,
'   GenerateCatalogs, generateSLQ and GenerateCSV.
'

!INC Local Scripts.EAConstants-VBScript
!INC DAF MDG.DAF M3 Conf

Const SCRIPT_VERSION = "1.3.1"

Const NS_DAF      = "https://freetakteam.github.io/DAF/model#"
Const NS_DAFM     = "https://freetakteam.github.io/DAF/metamodel#"
Const NS_DAFP     = "https://freetakteam.github.io/DAF/property#"
Const NS_DAFREL   = "https://freetakteam.github.io/DAF/relationship#"
Const NS_DAFPRED  = "https://freetakteam.github.io/DAF/predicate#"
Const NS_DAFSHAPE = "https://freetakteam.github.io/DAF/shape#"
Const NS_DAFENUM  = "https://freetakteam.github.io/DAF/enum#"
Const NS_DAFPKG   = "https://freetakteam.github.io/DAF/package#"
Const NS_DAFDEF   = "https://freetakteam.github.io/DAF/definition#"

Dim fso, rdfStream, reportStream
Dim conceptIriById, conceptLocalById, classIriById, classLocalById
Dim enumIriById, enumMembersByName
Dim usedConceptLocals, usedClassLocals, usedRelationshipLocals, usedPropertyLocals
Dim registeredClassGuids, exportedClassGuids
Dim registeredRelationshipGuids, generatedRelationshipGuids, generatedRelationshipLabels
Dim ignoredRelationshipGuids
Dim generatedConceptGuids
Dim legacyProfileConceptGuidMap, legacyProfileRelationshipGuidMap
Dim conceptCount, supportingClassCount, enumCount, attributeCount, relationshipCount
Dim inheritanceCount, taggedValueCount, constraintCount, warningCount
Dim ignoredNoteLinkCount
Dim legacyProfileConceptCount, legacyProfileRelationshipCount, quickLinkRuleCount

Set fso = CreateObject("Scripting.FileSystemObject")
Set conceptIriById = CreateObject("Scripting.Dictionary")
Set conceptLocalById = CreateObject("Scripting.Dictionary")
Set classIriById = CreateObject("Scripting.Dictionary")
Set classLocalById = CreateObject("Scripting.Dictionary")
Set enumIriById = CreateObject("Scripting.Dictionary")
Set enumMembersByName = CreateObject("Scripting.Dictionary")
Set usedConceptLocals = CreateObject("Scripting.Dictionary")
Set usedClassLocals = CreateObject("Scripting.Dictionary")
Set usedRelationshipLocals = CreateObject("Scripting.Dictionary")
Set usedPropertyLocals = CreateObject("Scripting.Dictionary")
Set registeredClassGuids = CreateObject("Scripting.Dictionary")
Set exportedClassGuids = CreateObject("Scripting.Dictionary")
Set registeredRelationshipGuids = CreateObject("Scripting.Dictionary")
Set generatedRelationshipGuids = CreateObject("Scripting.Dictionary")
Set generatedRelationshipLabels = CreateObject("Scripting.Dictionary")
Set ignoredRelationshipGuids = CreateObject("Scripting.Dictionary")
Set generatedConceptGuids = CreateObject("Scripting.Dictionary")
Set legacyProfileConceptGuidMap = CreateObject("Scripting.Dictionary")
Set legacyProfileRelationshipGuidMap = CreateObject("Scripting.Dictionary")

conceptIriById.CompareMode = 1
conceptLocalById.CompareMode = 1
classIriById.CompareMode = 1
classLocalById.CompareMode = 1
enumIriById.CompareMode = 1
enumMembersByName.CompareMode = 1
usedConceptLocals.CompareMode = 1
usedClassLocals.CompareMode = 1
usedRelationshipLocals.CompareMode = 1
usedPropertyLocals.CompareMode = 1
registeredClassGuids.CompareMode = 1
exportedClassGuids.CompareMode = 1
registeredRelationshipGuids.CompareMode = 1
generatedRelationshipGuids.CompareMode = 1
generatedRelationshipLabels.CompareMode = 1
ignoredRelationshipGuids.CompareMode = 1
generatedConceptGuids.CompareMode = 1
legacyProfileConceptGuidMap.CompareMode = 1
legacyProfileRelationshipGuidMap.CompareMode = 1

conceptCount = 0
supportingClassCount = 0
enumCount = 0
attributeCount = 0
relationshipCount = 0
inheritanceCount = 0
taggedValueCount = 0
constraintCount = 0
warningCount = 0
ignoredNoteLinkCount = 0
legacyProfileConceptCount = 0
legacyProfileRelationshipCount = 0
quickLinkRuleCount = 0

' ---------------------------------------------------------------------------
' Main
' ---------------------------------------------------------------------------

Sub GenerateDAFSemanticModel(packageGuid, outputFolder)
    Dim metamodelPackage, ttlPath, reportPath

    Repository.EnableUIUpdates = False
    Session.Output "DAF RDF generator " & SCRIPT_VERSION & " starting..."

    EnsureFolder outputFolder
    ttlPath = JoinPath(outputFolder, SafeFileName(ProfileName) & "-semantic-model.ttl")
    reportPath = JoinPath(outputFolder, SafeFileName(ProfileName) & "-semantic-model-report.txt")

    Set rdfStream = CreateObject("ADODB.Stream")
    rdfStream.Type = 2
    rdfStream.Charset = "utf-8"
    rdfStream.Open

    Set reportStream = CreateObject("ADODB.Stream")
    reportStream.Type = 2
    reportStream.Charset = "utf-8"
    reportStream.Open

    Report "DAF RDF Semantic Model generation report"
    Report "Generated: " & CStr(Now())
    Report "Script version: " & SCRIPT_VERSION
    Report "Profile name: " & CStr(ProfileName)
    Report ""
    ReportSharedConfiguration outputFolder
    AuditConfiguredLegacyArtifacts
    Report ""

    Set metamodelPackage = Repository.GetPackageByGuid(packageGuid)
    If metamodelPackage Is Nothing Then
        Report "ERROR: metamodel package not found for GUID " & packageGuid
        reportStream.SaveToFile reportPath, 2
        rdfStream.Close
        reportStream.Close
        Repository.EnableUIUpdates = True
        Session.Output "ERROR: Metamodel package not found."
        Exit Sub
    End If

    Report "Source package: " & metamodelPackage.Name
    Report "Source package GUID: " & metamodelPackage.PackageGUID
    Report ""

    WritePrefixes
    WriteOntologyHeader metamodelPackage
    WriteMetaMetamodelVocabulary
    WriteCommonModelElementVocabulary
    WriteCommonSHACL

    ' First pass creates stable IRIs and collects enumeration values so that
    ' all later references can resolve deterministically.
    RegisterPackage metamodelPackage

    ' Preserve source package structure/provenance.
    ExportPackageTree metamodelPackage

    ' Second pass exports concepts, properties, enums and constraints.
    ExportDefinitions metamodelPackage

    ' Third pass exports inheritance and first-class relationships.
    ExportRelationships metamodelPackage

    AuditGeneratedCompleteness
    WriteGenerationSummary metamodelPackage

    rdfStream.SaveToFile ttlPath, 2
    rdfStream.Close

    Report ""
    Report "SUMMARY"
    Report "DAF Concepts: " & conceptCount
    Report "Supporting M3 classes: " & supportingClassCount
    Report "Enumerations: " & enumCount
    Report "Attributes/property definitions: " & attributeCount
    Report "Relationships: " & relationshipCount
    Report "Ignored NoteLink connectors: " & ignoredNoteLinkCount
    Report "Generalizations: " & inheritanceCount
    Report "Tagged values preserved: " & taggedValueCount
    Report "Constraints preserved: " & constraintCount
    Report "Warnings: " & warningCount
    Report "Legacy profile element mappings: " & legacyProfileConceptCount
    Report "Legacy profile relationship mappings: " & legacyProfileRelationshipCount
    Report "QuickLink active rules: " & quickLinkRuleCount
    reportStream.SaveToFile reportPath, 2
    reportStream.Close

    Repository.EnableUIUpdates = True
    Session.Output "DAF RDF semantic model generated: " & ttlPath
    Session.Output "Generation report: " & reportPath
    Session.Output "Done at " & Now()
End Sub

Function GetRDFOutputFolder()
    Dim basePath
    basePath = Trim(CStr(TechFilePath))

    If basePath = "" Then
        basePath = ParentFolderOfFile(CStr(mdgTechFilePath))
    End If
    If basePath = "" Then
        basePath = ParentFolderOfFile(CStr(UMLProfileFilename))
    End If
    If basePath = "" Then
        basePath = Trim(CStr(CSVPath))
    End If

    If basePath = "" Then
        Session.Prompt "TechFilePath (or another configured output path) is empty in DAF M3 Conf.", promptOK
        GetRDFOutputFolder = ""
        Exit Function
    End If

    GetRDFOutputFolder = JoinPath(basePath, "rdf")
End Function

Function ParentFolderOfFile(filePath)
    Dim parentPath
    parentPath = ""
    On Error Resume Next
    If Trim(CStr(filePath)) <> "" Then parentPath = fso.GetParentFolderName(CStr(filePath))
    Err.Clear
    On Error GoTo 0
    ParentFolderOfFile = parentPath
End Function

Function SafeFileName(value)
    Dim s, badChars, i
    s = Trim(CStr(value))
    If s = "" Then s = "DAF"
    badChars = Array("\", "/", ":", "*", "?", Chr(34), "<", ">", "|")
    For i = 0 To UBound(badChars)
        s = Replace(s, badChars(i), "_")
    Next
    SafeFileName = s
End Function

Sub ReportSharedConfiguration(outputFolder)
    Report "SHARED CONFIGURATION"
    Report "metamodelPackageGUID: " & CStr(metamodelPackageGUID)
    Report "profilePackageGUID: " & CStr(profilePackageGUID)
    Report "relationshipPackageGUID: " & CStr(relationshipPackageGUID)
    Report "quickLinkFileName: " & CStr(quickLinkFileName)
    Report "ProfileName: " & CStr(ProfileName)
    Report "mdgTechFilePath: " & CStr(mdgTechFilePath)
    Report "TechFilePath: " & CStr(TechFilePath)
    Report "ProfileDiagramGUID: " & CStr(ProfileDiagramGUID)
    Report "UMLProfileFilename: " & CStr(UMLProfileFilename)
    Report "ProfileToolboxClassGUID: " & CStr(ProfileToolboxClassGUID)
    Report "ProfileToolboxConnectorGUID: " & CStr(ProfileToolboxConnectorGUID)
    Report "IconPath: " & CStr(IconPath)
    Report "SQLPath: " & CStr(SQLPath)
    Report "CSVPath: " & CStr(CSVPath)
    Report "GenerateCatalogs: " & CStr(GenerateCatalogs)
    Report "generateSLQ: " & CStr(generateSLQ)
    Report "GenerateCSV: " & CStr(GenerateCSV)
    Report "RDF output folder (derived): " & CStr(outputFolder)
    Report ""
End Sub

Sub AuditConfiguredLegacyArtifacts()
    Dim p, d, e

    Report "CONFIGURED LEGACY ARTIFACT AUDIT"

    Set p = SafeGetPackageByGuid(CStr(profilePackageGUID))
    If p Is Nothing Then
        Warn "Configured profilePackageGUID could not be resolved: " & CStr(profilePackageGUID)
    Else
        CollectProfileMappingsWithType p, "Element", legacyProfileConceptGuidMap
        legacyProfileConceptCount = legacyProfileConceptGuidMap.Count
        Report "Profile package: " & p.Name & " (unique mapped M3 element GUIDs: " & legacyProfileConceptCount & ")"
    End If

    Set p = SafeGetPackageByGuid(CStr(relationshipPackageGUID))
    If p Is Nothing Then
        Warn "Configured relationshipPackageGUID could not be resolved: " & CStr(relationshipPackageGUID)
    Else
        CollectProfileMappingsWithType p, "Connector", legacyProfileRelationshipGuidMap
        legacyProfileRelationshipCount = legacyProfileRelationshipGuidMap.Count
        Report "Relationship profile package: " & p.Name & " (unique mapped M3 connector GUIDs: " & legacyProfileRelationshipCount & ")"
    End If

    Set d = SafeGetDiagramByGuid(CStr(ProfileDiagramGUID))
    If d Is Nothing Then
        Warn "Configured ProfileDiagramGUID could not be resolved: " & CStr(ProfileDiagramGUID)
    Else
        Report "Profile diagram: " & d.Name
    End If

    Set e = SafeGetElementByGuid(CStr(ProfileToolboxClassGUID))
    If e Is Nothing Then
        Warn "Configured ProfileToolboxClassGUID could not be resolved: " & CStr(ProfileToolboxClassGUID)
    Else
        Report "Element toolbox class: " & e.Name
    End If

    Set e = SafeGetElementByGuid(CStr(ProfileToolboxConnectorGUID))
    If e Is Nothing Then
        Warn "Configured ProfileToolboxConnectorGUID could not be resolved: " & CStr(ProfileToolboxConnectorGUID)
    Else
        Report "Connector toolbox class: " & e.Name
    End If

    AuditConfiguredFile "QuickLink", CStr(quickLinkFileName), True
    AuditConfiguredFile "MDG technology source (MTS)", CStr(mdgTechFilePath), False
    AuditConfiguredFile "UML profile", CStr(UMLProfileFilename), False
    AuditConfiguredFolder "Technology", CStr(TechFilePath)
    AuditConfiguredFolder "Icons", CStr(IconPath)
    AuditConfiguredFolder "SQL", CStr(SQLPath)
    AuditConfiguredFolder "CSV", CStr(CSVPath)
End Sub

Sub AuditConfiguredFile(label, filePath, countQuickLink)
    If Trim(filePath) = "" Then
        Report label & ": not configured"
        Exit Sub
    End If

    If fso.FileExists(filePath) Then
        Report label & ": found - " & filePath
        If countQuickLink Then
            quickLinkRuleCount = CountQuickLinkRules(filePath)
            Report "QuickLink active rules: " & quickLinkRuleCount
        End If
    Else
        Report label & ": not found - " & filePath
    End If
End Sub

Sub AuditConfiguredFolder(label, folderPath)
    If Trim(folderPath) = "" Then
        Report label & " folder: not configured"
    ElseIf fso.FolderExists(folderPath) Then
        Report label & " folder: found - " & folderPath
    Else
        Report label & " folder: not found - " & folderPath
    End If
End Sub

Function CountQuickLinkRules(filePath)
    Dim ts, line, count
    count = 0
    On Error Resume Next
    Set ts = fso.OpenTextFile(filePath, 1, False)
    If Err.Number <> 0 Then
        Err.Clear
        CountQuickLinkRules = 0
        Exit Function
    End If
    On Error GoTo 0

    Do Until ts.AtEndOfStream
        line = Trim(ts.ReadLine)
        If line <> "" Then
            If Left(line, 2) <> "//" Then count = count + 1
        End If
    Loop
    ts.Close
    CountQuickLinkRules = count
End Function

Function CountProfileElementsWithType(pkg, profileType)
    Dim el, subPkg, count, t
    count = 0
    For Each el In pkg.Elements
        t = GetTaggedValue(el, "Profile Type")
        If LCase(Trim(t)) = LCase(Trim(profileType)) Then count = count + 1
    Next
    For Each subPkg In pkg.Packages
        count = count + CountProfileElementsWithType(subPkg, profileType)
    Next
    CountProfileElementsWithType = count
End Function

Sub CollectProfileMappingsWithType(pkg, profileType, targetMap)
    Dim el, subPkg, t, m3Guid, key, label
    For Each el In pkg.Elements
        t = GetTaggedValue(el, "Profile Type")
        If LCase(Trim(t)) = LCase(Trim(profileType)) Then
            m3Guid = Trim(GetTaggedValue(el, "Metamodel GUID"))
            If m3Guid <> "" Then
                key = LCase(m3Guid)
                label = HumanReadableProfileElementLabel(el)
                If Not targetMap.Exists(key) Then
                    targetMap.Add key, label
                Else
                    targetMap(key) = targetMap(key) & " | " & label
                End If
            Else
                Warn "Profile mapping '" & el.Name & "' (" & el.ElementGUID & ") has Profile Type '" & profileType & "' but no Metamodel GUID."
            End If
        End If
    Next
    For Each subPkg In pkg.Packages
        CollectProfileMappingsWithType subPkg, profileType, targetMap
    Next
End Sub

Function HumanReadableProfileElementLabel(el)
    Dim displayName
    displayName = Trim(CStr(el.Alias))
    If displayName = "" Then displayName = Trim(CStr(el.Name))
    If displayName = "" Then displayName = "Unnamed profile element"
    HumanReadableProfileElementLabel = "'" & displayName & "' [profile GUID=" & el.ElementGUID & "]"
End Function

Function SafeGetPackageByGuid(guid)
    Dim p
    Set p = Nothing
    On Error Resume Next
    If Trim(guid) <> "" Then Set p = Repository.GetPackageByGuid(guid)
    Err.Clear
    On Error GoTo 0
    Set SafeGetPackageByGuid = p
End Function

Function SafeGetElementByGuid(guid)
    Dim e
    Set e = Nothing
    On Error Resume Next
    If Trim(guid) <> "" Then Set e = Repository.GetElementByGuid(guid)
    Err.Clear
    On Error GoTo 0
    Set SafeGetElementByGuid = e
End Function

Function SafeGetDiagramByGuid(guid)
    Dim d
    Set d = Nothing
    On Error Resume Next
    If Trim(guid) <> "" Then Set d = Repository.GetDiagramByGuid(guid)
    Err.Clear
    On Error GoTo 0
    Set SafeGetDiagramByGuid = d
End Function

Sub AuditGeneratedCompleteness()
    Dim k, matched, profileOnly, m3Only, missingClasses, missingRelationships

    Report ""
    Report "COMPLETENESS CROSS-CHECK"
    Report "RDF DAF concepts generated: " & conceptCount
    Report "RDF supporting M3 classes generated: " & supportingClassCount
    Report "RDF relationships generated: " & relationshipCount
    Report "Ignored NoteLink connectors: " & ignoredNoteLinkCount

    missingClasses = 0
    For Each k In registeredClassGuids.Keys
        If Not exportedClassGuids.Exists(k) Then
            missingClasses = missingClasses + 1
            Warn "COMPLETENESS FAILURE: registered M3 class GUID " & k & " was not exported to RDF."
        End If
    Next
    Report "M3 classes represented in RDF: " & exportedClassGuids.Count & "/" & registeredClassGuids.Count

    missingRelationships = 0
    For Each k In registeredRelationshipGuids.Keys
        If Not generatedRelationshipGuids.Exists(k) Then
            missingRelationships = missingRelationships + 1
            Warn "COMPLETENESS FAILURE: registered M3 relationship " & registeredRelationshipGuids(k) & " [GUID=" & k & "] was not exported to RDF."
        End If
    Next
    Report "M3 non-generalization relationships represented in RDF: " & generatedRelationshipGuids.Count & "/" & registeredRelationshipGuids.Count

    If legacyProfileConceptGuidMap.Count > 0 Then
        matched = 0
        profileOnly = 0
        For Each k In legacyProfileConceptGuidMap.Keys
            If generatedConceptGuids.Exists(k) Then
                matched = matched + 1
            Else
                profileOnly = profileOnly + 1
                Report "PROFILE-ONLY ELEMENT MAPPING: " & legacyProfileConceptGuidMap(k) & " -> M3 GUID " & k
            End If
        Next

        m3Only = 0
        For Each k In generatedConceptGuids.Keys
            If Not legacyProfileConceptGuidMap.Exists(k) Then
                m3Only = m3Only + 1
                Report "M3 CONCEPT NOT MAPPED IN PROFILE: " & generatedConceptGuids(k) & " [GUID=" & k & "]"
            End If
        Next

        Report "Profile concept mappings matched by Metamodel GUID: " & matched
        Report "Profile-only element mappings: " & profileOnly
        Report "M3 concepts missing from generated profile: " & m3Only
    End If

    If legacyProfileRelationshipGuidMap.Count > 0 Then
        matched = 0
        profileOnly = 0
        For Each k In legacyProfileRelationshipGuidMap.Keys
            If generatedRelationshipGuids.Exists(k) Then
                matched = matched + 1
            ElseIf ignoredRelationshipGuids.Exists(k) Then
                Report "IGNORED NOTELINK PROFILE MAPPING: " & legacyProfileRelationshipGuidMap(k) & " -> M3 connector GUID " & k
            Else
                profileOnly = profileOnly + 1
                Report "PROFILE-ONLY RELATIONSHIP MAPPING: " & legacyProfileRelationshipGuidMap(k) & " -> M3 connector GUID " & k
            End If
        Next

        m3Only = 0
        For Each k In generatedRelationshipGuids.Keys
            If Not legacyProfileRelationshipGuidMap.Exists(k) Then
                m3Only = m3Only + 1
                Report "M3 RELATIONSHIP NOT MAPPED IN PROFILE: " & generatedRelationshipLabels(k) & " [GUID=" & k & "]"
            End If
        Next

        Report "Profile relationship mappings matched by Metamodel GUID: " & matched
        Report "Profile-only relationship mappings (excluding ignored NoteLinks): " & profileOnly
        Report "M3 relationships missing from generated relationship profile: " & m3Only
    End If

    If quickLinkRuleCount > 0 Then
        Report "QuickLink active rules: " & quickLinkRuleCount
        Report "NOTE: QuickLink rule count is not expected to equal relationship count because one relationship can generate multiple QuickLink rows."
    End If

    If missingClasses = 0 And missingRelationships = 0 Then
        Report "RDF completeness gate: PASS - every registered M3 class and exportable non-generalization relationship was represented; NoteLink connectors were intentionally ignored."
    Else
        Warn "RDF completeness gate: FAIL - " & missingClasses & " class(es) and " & missingRelationships & " relationship(s) disappeared during generation."
    End If
End Sub

' ---------------------------------------------------------------------------
' Turtle document header
' ---------------------------------------------------------------------------

Sub WritePrefixes()
    W "@prefix daf:      <" & NS_DAF & "> ."
    W "@prefix dafm:     <" & NS_DAFM & "> ."
    W "@prefix dafp:     <" & NS_DAFP & "> ."
    W "@prefix dafrel:   <" & NS_DAFREL & "> ."
    W "@prefix dafpred:  <" & NS_DAFPRED & "> ."
    W "@prefix dafshape: <" & NS_DAFSHAPE & "> ."
    W "@prefix dafenum:  <" & NS_DAFENUM & "> ."
    W "@prefix dafpkg:   <" & NS_DAFPKG & "> ."
    W "@prefix dafdef:   <" & NS_DAFDEF & "> ."
    W "@prefix rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ."
    W "@prefix rdfs:     <http://www.w3.org/2000/01/rdf-schema#> ."
    W "@prefix owl:      <http://www.w3.org/2002/07/owl#> ."
    W "@prefix xsd:      <http://www.w3.org/2001/XMLSchema#> ."
    W "@prefix sh:       <http://www.w3.org/ns/shacl#> ."
    W "@prefix skos:     <http://www.w3.org/2004/02/skos/core#> ."
    W "@prefix dcterms:  <http://purl.org/dc/terms/> ."
    W ""
End Sub

Sub WriteOntologyHeader(pkg)
    W "<https://freetakteam.github.io/DAF/ontology>"
    W "    a owl:Ontology ;"
    W "    dcterms:title " & Lit(CStr(ProfileName) & " Semantic Metamodel") & " ;"
    W "    dcterms:description " & Lit("Technology-independent RDF/OWL/SHACL representation generated from the authoritative DAF M3/M2 model.") & " ;"
    W "    dcterms:created " & TypedLit(IsoDateTime(Now()), "xsd:dateTime") & " ;"
    W "    dafm:generatorVersion " & Lit(SCRIPT_VERSION) & " ;"
    W "    dafm:sourcePackageGuid " & Lit(pkg.PackageGUID) & " ;"
    W "    dafm:sourcePackageName " & Lit(pkg.Name) & " ;"
    W "    dafm:profileName " & Lit(CStr(ProfileName)) & " ;"
    W "    dafm:configuredProfilePackageGuid " & Lit(CStr(profilePackageGUID)) & " ;"
    W "    dafm:configuredRelationshipPackageGuid " & Lit(CStr(relationshipPackageGUID)) & " ;"
    W "    dafm:configuredProfileDiagramGuid " & Lit(CStr(ProfileDiagramGUID)) & " ."
    W ""
End Sub

' ---------------------------------------------------------------------------
' Meta-metamodel vocabulary
' ---------------------------------------------------------------------------

Sub WriteMetaMetamodelVocabulary()
    W "# ---------------------------------------------------------------------"
    W "# DAF meta-metamodel vocabulary"
    W "# ---------------------------------------------------------------------"
    W ""

    ClassDef "dafm:ModelElement", "Model Element", "Vendor-neutral base class for all DAF M1 model elements."
    ClassDef "dafm:Relationship", "Relationship", "First-class relationship instance with source, target and a relationship type."
    W "dafm:Relationship rdfs:subClassOf dafm:ModelElement ."
    W ""

    ClassDef "dafm:ConceptDefinition", "Concept Definition", "M2 definition of a DAF modeling concept."
    ClassDef "dafm:PropertyDefinition", "Property Definition", "M2 definition of a semantic property originating from an M3 attribute."
    ClassDef "dafm:RelationshipType", "Relationship Type", "M2 first-class definition of a legal DAF relationship."
    ClassDef "dafm:RelationshipEnd", "Relationship End", "Definition of one end of a DAF relationship."
    ClassDef "dafm:Enumeration", "Enumeration", "M2 enumeration definition."
    ClassDef "dafm:EnumerationValue", "Enumeration Value", "A permitted value of an M2 enumeration."
    ClassDef "dafm:TaggedValue", "Tagged Value", "Source M3/EA tagged value preserved for traceability."
    ClassDef "dafm:Constraint", "Constraint", "Constraint preserved from the source M3 model."
    ClassDef "dafm:PackageDefinition", "Package Definition", "Source metamodel package used to organize DAF concepts."
    ClassDef "dafm:SupportingClassDefinition", "Supporting Class Definition", "Class found in the M3 package that is not stereotyped as Concept."
    ClassDef "dafm:OperationDefinition", "Operation Definition", "Operation/method definition preserved from the source M3 model."
    ClassDef "dafm:ParameterDefinition", "Parameter Definition", "Operation parameter definition preserved from the source M3 model."
    ClassDef "dafm:GenerationRecord", "Generation Record", "Metadata describing one generation of the semantic metamodel."
    ClassDef "dafm:GeneralizationDefinition", "Generalization Definition", "Source generalization preserved as both RDFS inheritance and an auditable M3 definition."
    W ""

    ObjectPropDef "dafm:source", "source", "Source model element of a first-class relationship."
    ObjectPropDef "dafm:target", "target", "Target model element of a first-class relationship."
    ObjectPropDef "dafm:relationshipType", "relationship type", "Relationship type instantiated by a first-class relationship."
    ObjectPropDef "dafm:sourceClass", "source class", "Allowed semantic source class of a relationship type."
    ObjectPropDef "dafm:targetClass", "target class", "Allowed semantic target class of a relationship type."
    ObjectPropDef "dafm:sourceEnd", "source end", "Source-end definition."
    ObjectPropDef "dafm:targetEnd", "target end", "Target-end definition."
    ObjectPropDef "dafm:projectionPredicate", "projection predicate", "OWL/RDF object property used as the direct graph projection of a first-class relationship."
    ObjectPropDef "dafm:inversePredicate", "inverse predicate", "Inverse OWL/RDF projection predicate."
    ObjectPropDef "dafm:definedInPackage", "defined in package", "Source package containing this metamodel definition."
    ObjectPropDef "dafm:hasPropertyDefinition", "has property definition", "Links a concept definition to one of its M3 attribute/property definitions."
    ObjectPropDef "dafm:hasTaggedValue", "has tagged value", "Links a metamodel object to a preserved tagged value."
    ObjectPropDef "dafm:hasConstraint", "has constraint", "Links a metamodel object to a preserved constraint."
    ObjectPropDef "dafm:enumeration", "enumeration", "Enumeration constraining a property definition."
    ObjectPropDef "dafm:parentPackage", "parent package", "Parent source package."
    ObjectPropDef "dafm:definedBy", "defined by", "Links a property, operation or parameter definition to its defining metamodel object."
    ObjectPropDef "dafm:endClass", "end class", "Class associated with a relationship end."
    ObjectPropDef "dafm:classifier", "classifier", "Classifier associated with an M3 attribute or parameter."
    W ""

    DataPropDef "dafm:eaGuid", "EA GUID", "Original Enterprise Architect GUID used for migration traceability.", "xsd:string"
    DataPropDef "dafm:umlMetaclass", "UML metaclass", "UML metaclass represented by a DAF concept or relationship.", "xsd:string"
    DataPropDef "dafm:redefines", "redefines", "External or internal stereotype redefined by the source M3 definition.", "xsd:string"
    DataPropDef "dafm:refines", "refines", "External semantic concept refined by the source M3 definition.", "xsd:string"
    DataPropDef "dafm:forwardRole", "forward role", "Forward semantic role/meaning from source to target.", "xsd:string"
    DataPropDef "dafm:backwardRole", "backward role", "Backward semantic role/meaning from target to source.", "xsd:string"
    DataPropDef "dafm:cardinality", "cardinality", "Cardinality text exactly as stored in the source model.", "xsd:string"
    DataPropDef "dafm:relationshipKind", "relationship kind", "UML/DAF relationship kind such as Association, Aggregation, Composition, Dependency, Generalization or Realization.", "xsd:string"
    DataPropDef "dafm:packagePath", "package path", "Human-readable package path in the source M3 model.", "xsd:string"
    DataPropDef "dafm:isDerived", "is derived", "Indicates a derived property or relationship end.", "xsd:boolean"
    DataPropDef "dafm:tagName", "tag name", "Original tagged-value name.", "xsd:string"
    DataPropDef "dafm:tagValue", "tag value", "Original tagged-value value.", "xsd:string"
    DataPropDef "dafm:tagNotes", "tag notes", "Original tagged-value notes where available.", "xsd:string"
    DataPropDef "dafm:constraintName", "constraint name", "Original constraint name.", "xsd:string"
    DataPropDef "dafm:constraintType", "constraint type", "Original constraint type.", "xsd:string"
    DataPropDef "dafm:constraintBody", "constraint body", "Original constraint body/notes.", "xsd:string"
    DataPropDef "dafm:generatorVersion", "generator version", "Version of this RDF generator.", "xsd:string"
    DataPropDef "dafm:sourcePackageGuid", "source package GUID", "GUID of the source M3 metamodel package.", "xsd:string"
    DataPropDef "dafm:sourcePackageName", "source package name", "Name of the source M3 metamodel package.", "xsd:string"
    DataPropDef "dafm:sourceDatatype", "source datatype", "Datatype exactly as defined on the M3 attribute.", "xsd:string"
    DataPropDef "dafm:minimumCardinality", "minimum cardinality", "Minimum cardinality preserved from an M3 attribute.", "xsd:string"
    DataPropDef "dafm:maximumCardinality", "maximum cardinality", "Maximum cardinality preserved from an M3 attribute.", "xsd:string"
    DataPropDef "dafm:sourceMultiplicity", "source multiplicity", "Multiplicity at the source/client end.", "xsd:string"
    DataPropDef "dafm:targetMultiplicity", "target multiplicity", "Multiplicity at the target/supplier end.", "xsd:string"
    DataPropDef "dafm:defaultValue", "default value", "Default value preserved from the M3 definition.", "xsd:string"
    DataPropDef "dafm:endKind", "end kind", "Source or target relationship end.", "xsd:string"
    DataPropDef "dafm:aggregation", "aggregation", "Aggregation semantics on a relationship end.", "xsd:string"
    DataPropDef "dafm:role", "role", "Role name on a relationship end.", "xsd:string"
    DataPropDef "dafm:roleNote", "role note", "Documentation associated with a relationship-end role.", "xsd:string"
    DataPropDef "dafm:navigable", "navigable", "EA navigability value for the relationship end.", "xsd:string"
    DataPropDef "dafm:endConstraint", "end constraint", "Constraint text attached to a relationship end.", "xsd:string"
    DataPropDef "dafm:containment", "containment", "Containment semantics on a relationship end.", "xsd:string"
    DataPropDef "dafm:qualifier", "qualifier", "Qualifier attached to a relationship end.", "xsd:string"
    DataPropDef "dafm:visibility", "visibility", "Visibility preserved from the source definition.", "xsd:string"
    DataPropDef "dafm:stereotype", "stereotype", "Stereotype preserved from the source definition.", "xsd:string"
    DataPropDef "dafm:endAlias", "end alias", "Alias of a relationship end.", "xsd:string"
    DataPropDef "dafm:allowDuplicates", "allow duplicates", "Whether duplicate values are allowed at a relationship end.", "xsd:boolean"
    DataPropDef "dafm:derivedUnion", "derived union", "Whether a relationship end is a derived union.", "xsd:boolean"
    DataPropDef "dafm:isChangeable", "is changeable", "EA changeability setting for a relationship end.", "xsd:string"
    DataPropDef "dafm:ordering", "ordering", "Ordering value for a relationship end.", "xsd:integer"
    DataPropDef "dafm:ownedByClassifier", "owned by classifier", "Whether the relationship end is owned by its classifier.", "xsd:boolean"
    DataPropDef "dafm:roleType", "role type", "Role type associated with a relationship end.", "xsd:string"
    DataPropDef "dafm:returnType", "return type", "Return type of an M3 operation.", "xsd:string"
    DataPropDef "dafm:parameterType", "parameter type", "Type of an operation parameter.", "xsd:string"
    DataPropDef "dafm:parameterPosition", "parameter position", "Ordinal position of an operation parameter.", "xsd:integer"
    DataPropDef "dafm:ownerKind", "owner kind", "Kind of source object owning a preserved tag or constraint.", "xsd:string"
    DataPropDef "dafm:constraintStatus", "constraint status", "Status of a preserved source constraint.", "xsd:string"
    DataPropDef "dafm:sourceStatus", "source status", "Status metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourceVersion", "source version", "Version metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourcePhase", "source phase", "Phase metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourceStereotype", "source stereotype", "Stereotype metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourceModelType", "source model type", "EA model type of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourceVisibility", "source visibility", "Visibility metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourceComplexity", "source complexity", "Complexity metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourcePersistence", "source persistence", "Persistence metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourcePriority", "source priority", "Priority metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:sourceLanguage", "source language", "Generation/specification language metadata of the M2 source definition.", "xsd:string"
    DataPropDef "dafm:attributeAlias", "attribute alias", "Alias of an M3 attribute.", "xsd:string"
    DataPropDef "dafm:attributeVisibility", "attribute visibility", "Visibility of an M3 attribute.", "xsd:string"
    DataPropDef "dafm:attributeStereotype", "attribute stereotype", "Applied stereotype(s) of an M3 attribute.", "xsd:string"
    DataPropDef "dafm:isCollection", "is collection", "Whether an M3 attribute is a collection.", "xsd:boolean"
    DataPropDef "dafm:isConst", "is const", "Whether an M3 attribute is constant.", "xsd:boolean"
    DataPropDef "dafm:isId", "is ID", "Whether an M3 attribute identifies an instance.", "xsd:boolean"
    DataPropDef "dafm:isOrdered", "is ordered", "Whether an M3 attribute collection is ordered.", "xsd:boolean"
    DataPropDef "dafm:isStatic", "is static", "Whether an M3 attribute is static.", "xsd:boolean"
    DataPropDef "dafm:attributeLength", "attribute length", "Length metadata of an M3 attribute.", "xsd:string"
    DataPropDef "dafm:attributeContainer", "attribute container", "Container metadata of an M3 attribute.", "xsd:string"
    DataPropDef "dafm:attributeContainment", "attribute containment", "Containment metadata of an M3 attribute.", "xsd:string"
    DataPropDef "dafm:sourceConnectorType", "source connector type", "EA connector type from which a relationship type was generated.", "xsd:string"
    DataPropDef "dafm:sourceDirection", "source direction", "EA connector direction metadata.", "xsd:string"
    DataPropDef "dafm:conceptCount", "concept count", "Number of generated DAF concepts.", "xsd:integer"
    DataPropDef "dafm:enumerationCount", "enumeration count", "Number of generated enumerations.", "xsd:integer"
    DataPropDef "dafm:propertyCount", "property count", "Number of generated semantic property definitions.", "xsd:integer"
    DataPropDef "dafm:relationshipCount", "relationship count", "Number of generated relationship types.", "xsd:integer"
    DataPropDef "dafm:ignoredNoteLinkCount", "ignored NoteLink count", "Number of EA NoteLink connectors intentionally excluded from semantic relationship generation.", "xsd:integer"
    DataPropDef "dafm:generalizationCount", "generalization count", "Number of generated inheritance links.", "xsd:integer"
    DataPropDef "dafm:warningCount", "warning count", "Number of generator warnings.", "xsd:integer"
    W ""
    DataPropDef "dafm:supportingClassCount", "supporting class count", "Number of generated supporting M3 classes.", "xsd:integer"
    DataPropDef "dafm:registeredClassCount", "registered M3 class count", "Number of M3 classes registered during the generation pass.", "xsd:integer"
    DataPropDef "dafm:registeredRelationshipCount", "registered M3 relationship count", "Number of non-generalization M3 relationships registered during the generation pass.", "xsd:integer"
    DataPropDef "dafm:relationshipKindSource", "relationship kind source", "How the semantic relationship kind was determined: Metaclass, Redefines, or EAConnectorTypeFallback.", "xsd:string"
End Sub

' ---------------------------------------------------------------------------
' Common vendor-neutral properties inherited from the modeling platform today.
' These are generated explicitly because they are not M3 tagged-value attributes.
' ---------------------------------------------------------------------------

Sub WriteCommonModelElementVocabulary()
    W "# ---------------------------------------------------------------------"
    W "# Common DAF ModelElement metadata"
    W "# ---------------------------------------------------------------------"
    W ""

    CommonProp "id", "Identifier", "Stable identifier of a model element.", "xsd:string"
    CommonProp "name", "Name", "Human-readable name of a model element.", "xsd:string"
    CommonProp "alias", "Alias", "Optional alternate name.", "xsd:string"
    CommonProp "notes", "Notes", "Human-readable documentation.", "xsd:string"
    CommonProp "status", "Status", "Lifecycle or governance status.", "xsd:string"
    CommonProp "version", "Version", "Version associated with the model element.", "xsd:string"
    CommonProp "phase", "Phase", "Lifecycle or project phase.", "xsd:string"
    CommonProp "author", "Author", "Author responsible for the model element.", "xsd:string"
    CommonProp "createdAt", "Created at", "Creation timestamp.", "xsd:dateTime"
    CommonProp "modifiedAt", "Modified at", "Last-modified timestamp.", "xsd:dateTime"
    CommonProp "visibility", "Visibility", "Visibility such as Public, Private, Protected or Package.", "xsd:string"
    CommonProp "modelType", "Model type", "Underlying modeling type such as Class, Component, Actor or Requirement.", "xsd:string"
    CommonProp "stereotype", "Stereotype", "Applied modeling stereotype.", "xsd:string"
    CommonProp "keywords", "Keywords", "Keywords associated with the model element.", "xsd:string"
    CommonProp "complexity", "Complexity", "Modeling or implementation complexity.", "xsd:string"
    CommonProp "multiplicity", "Multiplicity", "Multiplicity associated with the model element.", "xsd:string"
    CommonProp "persistence", "Persistence", "Persistence classification such as Persistent or Transient.", "xsd:string"
    CommonProp "priority", "Priority", "Priority where applicable.", "xsd:string"
    CommonProp "language", "Language", "Implementation or specification language where applicable.", "xsd:string"
    CommonBoolProp "isAbstract", "Is abstract", "Whether the model element is abstract."
    CommonBoolProp "isLeaf", "Is leaf", "Whether the model element is final/leaf."
    CommonBoolProp "isRoot", "Is root", "Whether the model element is a root."
    ObjectPropDef "dafp:package", "package", "Package containing the model element."
    ObjectPropDef "dafp:parent", "parent", "Parent model element."
    W ""
End Sub

Sub WriteCommonSHACL()
    W "# ---------------------------------------------------------------------"
    W "# Common SHACL constraints"
    W "# ---------------------------------------------------------------------"
    W ""
    W "dafshape:ModelElementShape"
    W "    a sh:NodeShape ;"
    W "    sh:targetClass dafm:ModelElement ;"
    W "    sh:property ["
    W "        sh:path dafp:id ;"
    W "        sh:datatype xsd:string ;"
    W "        sh:minCount 1 ;"
    W "        sh:maxCount 1"
    W "    ] ;"
    W "    sh:property ["
    W "        sh:path dafp:name ;"
    W "        sh:datatype xsd:string ;"
    W "        sh:minCount 1 ;"
    W "        sh:maxCount 1"
    W "    ] ."
    W ""

    W "dafshape:RelationshipShape"
    W "    a sh:NodeShape ;"
    W "    sh:targetClass dafm:Relationship ;"
    W "    sh:property [ sh:path dafm:source ; sh:minCount 1 ; sh:maxCount 1 ; sh:class dafm:ModelElement ] ;"
    W "    sh:property [ sh:path dafm:target ; sh:minCount 1 ; sh:maxCount 1 ; sh:class dafm:ModelElement ] ."
    W ""
End Sub

' ---------------------------------------------------------------------------
' Registration pass
' ---------------------------------------------------------------------------

Sub RegisterPackage(pkg)
    Dim el, subPkg, c, connectorKey
    For Each el In pkg.Elements
        If LCase(el.Type) = "class" Then
            If LCase(el.Stereotype) = "concept" Then
                RegisterConcept el
            Else
                RegisterSupportingClass el
            End If

            If Not registeredClassGuids.Exists(LCase(el.ElementGUID)) Then
                registeredClassGuids.Add LCase(el.ElementGUID), HumanReadableElementLabel(el.ElementID)
            End If

            For Each c In el.Connectors
                If c.ClientID = el.ElementID Then
                    connectorKey = LCase(c.ConnectorGUID)
                    If IsIgnoredRelationshipConnector(c) Then
                        If Not ignoredRelationshipGuids.Exists(connectorKey) Then
                            ignoredRelationshipGuids.Add connectorKey, RelationshipRegistrationLabel(c)
                            ignoredNoteLinkCount = ignoredNoteLinkCount + 1
                        End If
                    ElseIf LCase(c.Type) <> "generalization" Then
                        If Not registeredRelationshipGuids.Exists(connectorKey) Then
                            registeredRelationshipGuids.Add connectorKey, RelationshipRegistrationLabel(c)
                        End If
                    End If
                End If
            Next
        ElseIf LCase(el.Type) = "enumeration" Then
            RegisterEnumeration el
        End If
    Next

    For Each subPkg In pkg.Packages
        RegisterPackage subPkg
    Next
End Sub

Sub RegisterConcept(el)
    Dim baseLocal, localName, key
    baseLocal = SafeLocal(el.Name)
    localName = UniqueClassLocal(baseLocal, el.ElementGUID)
    key = LCase(localName)

    If usedConceptLocals.Exists(LCase(baseLocal)) Then
        Warn "Duplicate concept local name '" & baseLocal & "'. Using " & localName & " for " & el.ElementGUID
    End If

    usedConceptLocals(LCase(baseLocal)) = True
    conceptIriById.Add CStr(el.ElementID), "daf:" & localName
    conceptLocalById.Add CStr(el.ElementID), localName
    classIriById.Add CStr(el.ElementID), "daf:" & localName
    classLocalById.Add CStr(el.ElementID), localName
End Sub

Sub RegisterSupportingClass(el)
    Dim baseLocal, localName
    baseLocal = "SupportingClass_" & SafeLocal(el.Name)
    localName = UniqueClassLocal(baseLocal, el.ElementGUID)
    classIriById.Add CStr(el.ElementID), "dafdef:" & localName
    classLocalById.Add CStr(el.ElementID), localName
End Sub

Function UniqueClassLocal(baseLocal, guid)
    Dim localName, key
    localName = baseLocal
    key = LCase(localName)
    If usedClassLocals.Exists(key) Then
        localName = baseLocal & "_" & ShortGuid(guid)
        Warn "Duplicate M3 class local name '" & baseLocal & "'. Using " & localName & " for " & guid
    End If
    usedClassLocals.Add LCase(localName), True
    UniqueClassLocal = localName
End Function

Sub RegisterEnumeration(el)
    Dim enumLocal, enumIri, a, members, delimiter
    delimiter = Chr(30)
    enumLocal = SafeLocal(el.Name)
    enumIri = "dafenum:" & enumLocal

    enumIriById.Add CStr(el.ElementID), enumIri

    members = ""
    For Each a In el.Attributes
        If members <> "" Then members = members & delimiter
        members = members & a.Name
    Next

    If Not enumMembersByName.Exists(el.Name) Then
        enumMembersByName.Add el.Name, members
    Else
        Warn "Duplicate enumeration name '" & el.Name & "'. Attribute type resolution may be ambiguous."
    End If
End Sub

' ---------------------------------------------------------------------------
' Package/provenance export
' ---------------------------------------------------------------------------

Sub ExportPackageTree(pkg)
    Dim pkgIri, parentPkg, subPkg
    pkgIri = PackageIri(pkg)

    W pkgIri
    W "    a dafm:PackageDefinition ;"
    W "    rdfs:label " & Lit(pkg.Name) & " ;"
    W "    dafm:eaGuid " & Lit(pkg.PackageGUID) & " ;"
    W "    dafm:packagePath " & Lit(GetPackagePath(pkg)) & PackageEndPredicate(pkg)
    W ""

    On Error Resume Next
    ExportElementCommonMetadata pkgIri, pkg.Element
    ExportTaggedValues pkgIri, pkg.PackageGUID, pkg.Element.TaggedValues, "package"
    ExportConstraints pkgIri, pkg.PackageGUID, pkg.Element.Constraints, "package"
    Err.Clear
    On Error GoTo 0

    If pkg.ParentID <> 0 Then
        On Error Resume Next
        Set parentPkg = Repository.GetPackageByID(pkg.ParentID)
        If Err.Number = 0 And Not parentPkg Is Nothing Then
            W pkgIri & " dafm:parentPackage " & PackageIri(parentPkg) & " ."
            W ""
        End If
        Err.Clear
        On Error GoTo 0
    End If

    For Each subPkg In pkg.Packages
        ExportPackageTree subPkg
    Next
End Sub

Function PackageEndPredicate(pkg)
    Dim notes
    notes = SafeGetPackageNotes(pkg)
    If notes <> "" Then
        PackageEndPredicate = " ;" & vbCrLf & "    rdfs:comment " & Lit(notes) & " ."
    Else
        PackageEndPredicate = " ."
    End If
End Function

' ---------------------------------------------------------------------------
' Definition export pass
' ---------------------------------------------------------------------------

Sub ExportDefinitions(pkg)
    Dim el, subPkg

    For Each el In pkg.Elements
        If LCase(el.Type) = "class" Then
            If LCase(el.Stereotype) = "concept" Then
                ExportConcept el, pkg
            Else
                ExportSupportingClass el, pkg
            End If
        ElseIf LCase(el.Type) = "enumeration" Then
            ExportEnumeration el, pkg
        End If
    Next

    For Each subPkg In pkg.Packages
        ExportDefinitions subPkg
    Next
End Sub

Sub ExportConcept(el, pkg)
    Dim iri, localName, metaclassName, redefinesName, refinesName
    Dim superCount, a

    iri = ConceptIri(el.ElementID)
    localName = ConceptLocal(el.ElementID)
    metaclassName = GetTaggedValue(el, "Metaclass")
    redefinesName = GetTaggedValue(el, "Redefines")
    refinesName = GetTaggedValue(el, "Refines")

    conceptCount = conceptCount + 1
    If Not generatedConceptGuids.Exists(LCase(el.ElementGUID)) Then generatedConceptGuids.Add LCase(el.ElementGUID), HumanReadableElementLabel(el.ElementID)
    If Not exportedClassGuids.Exists(LCase(el.ElementGUID)) Then exportedClassGuids.Add LCase(el.ElementGUID), iri

    W "# Concept: " & HumanReadableName(el)
    W iri
    W "    a owl:Class, dafm:ConceptDefinition ;"
    W "    rdfs:label " & Lit(HumanReadableName(el)) & " ;"
    W "    skos:notation " & Lit(el.Name) & " ;"
    W "    dafm:eaGuid " & Lit(el.ElementGUID) & " ;"
    W "    dafm:definedInPackage " & PackageIri(pkg) & " ;"
    W "    dafm:packagePath " & Lit(GetPackagePath(pkg)) & ConceptMetadataTail(el, metaclassName, redefinesName, refinesName)
    W ""

    ' Every DAF concept is explicitly a ModelElement regardless of its other
    ' generalizations. This avoids reliance on external superclass reasoning.
    superCount = ExportGeneralizations(el)
    If metaclassName = "" And redefinesName = "" And superCount = 0 Then
        Warn "Concept '" & el.Name & "' has no Metaclass, Redefines value or superclass. It was exported but would not be transformed by the legacy UML Profile generator."
    End If
    W iri & " rdfs:subClassOf dafm:ModelElement ."
    W ""

    ' A Concept-specific shape inherits the common ModelElement shape and receives
    ' generated property/relationship constraints.
    W "dafshape:" & localName & "Shape"
    W "    a sh:NodeShape ;"
    W "    sh:targetClass " & iri & " ;"
    W "    sh:node dafshape:ModelElementShape ."
    W ""

    ExportElementCommonMetadata iri, el
    ExportTaggedValues iri, el.ElementGUID, el.TaggedValues, "element"
    ExportConstraints iri, el.ElementGUID, el.Constraints, "element"

    For Each a In el.Attributes
        ExportAttribute el, a
    Next

    ExportMethods el
End Sub

Function ConceptMetadataTail(el, metaclassName, redefinesName, refinesName)
    Dim s
    s = ""

    If el.Alias <> "" And LCase(Trim(el.Alias)) <> LCase(Trim(el.Name)) Then s = s & " ;" & vbCrLf & "    skos:altLabel " & Lit(el.Name)
    If el.Notes <> "" Then s = s & " ;" & vbCrLf & "    rdfs:comment " & Lit(el.Notes)
    If metaclassName <> "" Then s = s & " ;" & vbCrLf & "    dafm:umlMetaclass " & Lit(metaclassName)
    If redefinesName <> "" Then s = s & " ;" & vbCrLf & "    dafm:redefines " & Lit(redefinesName)
    If refinesName <> "" Then s = s & " ;" & vbCrLf & "    dafm:refines " & Lit(refinesName)
    s = s & " ."
    ConceptMetadataTail = s
End Function

Sub ExportSupportingClass(el, pkg)
    Dim iri, localName, a, superCount
    iri = ClassIri(el.ElementID)
    localName = ClassLocal(el.ElementID)
    supportingClassCount = supportingClassCount + 1
    If Not exportedClassGuids.Exists(LCase(el.ElementGUID)) Then exportedClassGuids.Add LCase(el.ElementGUID), iri

    W "# Supporting M3 class: " & HumanReadableName(el)
    W iri
    W "    a owl:Class, dafm:SupportingClassDefinition ;"
    W "    rdfs:label " & Lit(HumanReadableName(el)) & " ;"
    W "    skos:notation " & Lit(el.Name) & " ;"
    W "    dafm:eaGuid " & Lit(el.ElementGUID) & " ;"
    W "    dafm:definedInPackage " & PackageIri(pkg) & SupportingClassTail(el)
    W ""

    superCount = ExportGeneralizations(el)
    W iri & " rdfs:subClassOf dafm:ModelElement ."
    W ""

    W "dafshape:" & localName & "Shape"
    W "    a sh:NodeShape ;"
    W "    sh:targetClass " & iri & " ;"
    W "    sh:node dafshape:ModelElementShape ."
    W ""

    ExportElementCommonMetadata iri, el
    ExportTaggedValues iri, el.ElementGUID, el.TaggedValues, "supportingClass"
    ExportConstraints iri, el.ElementGUID, el.Constraints, "supportingClass"

    For Each a In el.Attributes
        ExportAttribute el, a
    Next
    ExportMethods el
End Sub

Function SupportingClassTail(el)
    Dim s
    s = ""
    If el.Notes <> "" Then s = s & " ;" & vbCrLf & "    rdfs:comment " & Lit(el.Notes)
    s = s & " ."
    SupportingClassTail = s
End Function

Sub ExportEnumeration(el, pkg)
    Dim enumIri, a, valueIri, index
    enumIri = EnumerationIri(el.ElementID)
    enumCount = enumCount + 1

    W "# Enumeration: " & el.Name
    W enumIri
    W "    a dafm:Enumeration, skos:ConceptScheme ;"
    W "    rdfs:label " & Lit(el.Name) & " ;"
    W "    dafm:eaGuid " & Lit(el.ElementGUID) & " ;"
    W "    dafm:definedInPackage " & PackageIri(pkg) & EnumMetadataTail(el)
    W ""

    ExportTaggedValues enumIri, el.ElementGUID, el.TaggedValues, "enumeration"
    ExportConstraints enumIri, el.ElementGUID, el.Constraints, "enumeration"

    index = 0
    For Each a In el.Attributes
        index = index + 1
        valueIri = enumIri & "_value_" & SafeLocal(a.Name)
        W valueIri
        W "    a dafm:EnumerationValue, skos:Concept ;"
        W "    skos:inScheme " & enumIri & " ;"
        W "    skos:prefLabel " & Lit(a.Name) & " ;"
        W "    dafm:eaGuid " & Lit(a.AttributeGUID) & EnumValueTail(a)
        W ""
        ExportTaggedValues valueIri, a.AttributeGUID, a.TaggedValues, "enumValue"
        ExportConstraints valueIri, a.AttributeGUID, a.Constraints, "enumValue"
    Next

    If index = 0 Then Warn "Enumeration '" & el.Name & "' has no values."
End Sub

Function EnumMetadataTail(el)
    Dim s
    s = ""
    If el.Notes <> "" Then s = s & " ;" & vbCrLf & "    rdfs:comment " & Lit(el.Notes)
    s = s & " ."
    EnumMetadataTail = s
End Function

Function EnumValueTail(a)
    Dim s, d
    s = ""
    If a.Notes <> "" Then s = s & " ;" & vbCrLf & "    rdfs:comment " & Lit(a.Notes)
    d = SafeAttributeDefault(a)
    If d <> "" Then s = s & " ;" & vbCrLf & "    dafm:defaultValue " & Lit(d)
    s = s & " ."
    EnumValueTail = s
End Function

' ---------------------------------------------------------------------------
' Generalization/inheritance
' ---------------------------------------------------------------------------

Function ExportGeneralizations(el)
    Dim c, supplierIri, supplierEl, n, genIri, genLabel
    n = 0

    For Each c In el.Connectors
        If c.ClientID = el.ElementID And LCase(c.Type) = "generalization" Then
            supplierIri = ""
            Set supplierEl = Nothing

            If classIriById.Exists(CStr(c.SupplierID)) Then
                supplierIri = ClassIri(c.SupplierID)
                Set supplierEl = Repository.GetElementByID(c.SupplierID)
            Else
                On Error Resume Next
                Set supplierEl = Repository.GetElementByID(c.SupplierID)
                If Err.Number = 0 And Not supplierEl Is Nothing Then
                    supplierIri = "dafdef:ExternalSuperclass_" & SafeLocal(supplierEl.Name) & "_" & ShortGuid(supplierEl.ElementGUID)
                    W supplierIri & " a owl:Class ; rdfs:label " & Lit(supplierEl.Name) & " ; dafm:eaGuid " & Lit(supplierEl.ElementGUID) & " ."
                End If
                Err.Clear
                On Error GoTo 0
            End If

            If supplierIri <> "" Then
                W ClassIri(el.ElementID) & " rdfs:subClassOf " & supplierIri & " ."

                genIri = "dafdef:Generalization_" & ShortGuid(c.ConnectorGUID)
                If Not supplierEl Is Nothing Then
                    genLabel = el.Name & " generalizes to " & supplierEl.Name
                Else
                    genLabel = el.Name & " generalization"
                End If

                W genIri
                W "    a dafm:GeneralizationDefinition ;"
                W "    rdfs:label " & Lit(genLabel) & " ;"
                W "    dafm:eaGuid " & Lit(c.ConnectorGUID) & " ;"
                W "    dafm:sourceClass " & ClassIri(el.ElementID) & " ;"
                W "    dafm:targetClass " & supplierIri & " ;"
                W "    dafm:relationshipKind " & Lit("Generalization") & GeneralizationTail(c)
                W ""

                ExportTaggedValues genIri, c.ConnectorGUID, c.TaggedValues, "generalization"
                ExportConstraints genIri, c.ConnectorGUID, c.Constraints, "generalization"

                inheritanceCount = inheritanceCount + 1
                n = n + 1
            Else
                Warn "Could not resolve superclass for M3 class '" & el.Name & "', connector " & c.ConnectorGUID
            End If
        End If
    Next

    If n > 0 Then W ""
    ExportGeneralizations = n
End Function

Function GeneralizationTail(c)
    Dim s, redefinesName, refinesName
    s = ""
    redefinesName = GetTaggedValue(c, "Redefines")
    refinesName = GetTaggedValue(c, "Refines")
    If c.Notes <> "" Then s = s & " ;" & vbCrLf & "    rdfs:comment " & Lit(c.Notes)
    If redefinesName <> "" Then s = s & " ;" & vbCrLf & "    dafm:redefines " & Lit(redefinesName)
    If refinesName <> "" Then s = s & " ;" & vbCrLf & "    dafm:refines " & Lit(refinesName)
    s = s & " ."
    GeneralizationTail = s
End Function

' ---------------------------------------------------------------------------
' Attribute/property export
' ---------------------------------------------------------------------------

Sub ExportAttribute(ownerEl, a)
    Dim ownerIri, ownerLocal, propLocal, propIri, defIri
    Dim xsdType, enumIri, lowerBound, upperBound, isEnum, defaultValue
    Dim classifierIri

    ownerIri = ClassIri(ownerEl.ElementID)
    ownerLocal = ClassLocal(ownerEl.ElementID)
    propLocal = UniquePropertyLocal(ownerLocal & "__" & SafeLocal(a.Name), a.AttributeGUID)
    propIri = "dafp:" & propLocal
    defIri = "dafdef:Property_" & StableIdentityLocal(a.AttributeGUID, propLocal)

    attributeCount = attributeCount + 1

    isEnum = False
    enumIri = ""
    If enumMembersByName.Exists(a.Type) Then
        isEnum = True
        enumIri = "dafenum:" & SafeLocal(a.Type)
        xsdType = "xsd:string"
    Else
        xsdType = MapDatatype(a.Type)
    End If

    lowerBound = SafeAttributeLowerBound(a)
    upperBound = SafeAttributeUpperBound(a)
    defaultValue = SafeAttributeDefault(a)

    W defIri
    W "    a dafm:PropertyDefinition ;"
    W "    rdfs:label " & Lit(a.Name) & " ;"
    W "    dafm:eaGuid " & Lit(a.AttributeGUID) & " ;"
    W "    dafm:sourceDatatype " & Lit(a.Type) & " ;"
    W "    dafm:isDerived " & BoolLit(a.IsDerived) & " ;"
    W "    dafm:projectionPredicate " & propIri & AttributeDefinitionTail(a, lowerBound, upperBound, defaultValue, isEnum, enumIri)
    W ""

    W ownerIri & " dafm:hasPropertyDefinition " & defIri & " ."
    W ""

    W propIri
    W "    a owl:DatatypeProperty ;"
    W "    rdfs:label " & Lit(a.Name) & " ;"
    W "    rdfs:domain " & ownerIri & " ;"
    W "    rdfs:range " & xsdType & PropertyCommentTail(a)
    W ""

    ExportTaggedValues defIri, a.AttributeGUID, a.TaggedValues, "attribute"
    ExportConstraints defIri, a.AttributeGUID, a.Constraints, "attribute"
    ExportAttributeExtraMetadata defIri, a

    ' Property SHACL is attached to the owning M3 class shape.
    W "dafshape:" & ownerLocal & "Shape sh:property ["
    W "    sh:path " & propIri & " ;"
    If isEnum Then
        W "    sh:datatype xsd:string ;"
        WriteShInList a.Type
    Else
        W "    sh:datatype " & xsdType & " ;"
    End If

    If Not a.IsDerived Then
        WriteMinMaxCount lowerBound, upperBound
    Else
        ' Derived properties are preserved semantically but not required for input.
        If ParseMaxCardinality(upperBound) >= 0 Then
            W "    sh:maxCount " & ParseMaxCardinality(upperBound) & " ;"
        End If
    End If

    W "    sh:name " & Lit(a.Name)
    W "] ."
    W ""
End Sub

Function AttributeDefinitionTail(a, lowerBound, upperBound, defaultValue, isEnum, enumIri)
    Dim s
    s = ""

    If a.Notes <> "" Then s = s & " ;" & vbCrLf & "    rdfs:comment " & Lit(a.Notes)
    If lowerBound <> "" Then s = s & " ;" & vbCrLf & "    dafm:minimumCardinality " & Lit(lowerBound)
    If upperBound <> "" Then s = s & " ;" & vbCrLf & "    dafm:maximumCardinality " & Lit(upperBound)
    If defaultValue <> "" Then s = s & " ;" & vbCrLf & "    dafm:defaultValue " & Lit(defaultValue)
    If isEnum Then s = s & " ;" & vbCrLf & "    dafm:enumeration " & enumIri
    s = s & " ."
    AttributeDefinitionTail = s
End Function

Function PropertyCommentTail(a)
    If a.Notes <> "" Then
        PropertyCommentTail = " ;" & vbCrLf & "    rdfs:comment " & Lit(a.Notes) & " ."
    Else
        PropertyCommentTail = " ."
    End If
End Function

Sub ExportAttributeExtraMetadata(defIri, a)
    Dim v, classifierId, classifierEl, classifierIri

    On Error Resume Next

    v = a.Alias
    If Err.Number = 0 And v <> "" Then W defIri & " dafm:attributeAlias " & Lit(v) & " ."
    Err.Clear

    v = a.Visibility
    If Err.Number = 0 And v <> "" Then W defIri & " dafm:attributeVisibility " & Lit(v) & " ."
    Err.Clear

    v = a.StereotypeEx
    If Err.Number <> 0 Or v = "" Then
        Err.Clear
        v = a.Stereotype
    End If
    If Err.Number = 0 And v <> "" Then W defIri & " dafm:attributeStereotype " & Lit(v) & " ."
    Err.Clear

    W defIri & " dafm:isCollection " & BoolLit(a.IsCollection) & " ."
    Err.Clear
    W defIri & " dafm:isConst " & BoolLit(a.IsConst) & " ."
    Err.Clear
    W defIri & " dafm:isId " & BoolLit(a.IsID) & " ."
    Err.Clear
    W defIri & " dafm:isOrdered " & BoolLit(a.IsOrdered) & " ."
    Err.Clear
    W defIri & " dafm:isStatic " & BoolLit(a.IsStatic) & " ."
    Err.Clear

    v = a.Length
    If Err.Number = 0 And v <> "" Then W defIri & " dafm:attributeLength " & Lit(v) & " ."
    Err.Clear

    v = a.Container
    If Err.Number = 0 And v <> "" Then W defIri & " dafm:attributeContainer " & Lit(v) & " ."
    Err.Clear

    v = a.Containment
    If Err.Number = 0 And v <> "" Then W defIri & " dafm:attributeContainment " & Lit(v) & " ."
    Err.Clear

    classifierId = a.ClassifierID
    If Err.Number = 0 And CStr(classifierId) <> "" And CStr(classifierId) <> "0" Then
        classifierIri = ""
        If classIriById.Exists(CStr(classifierId)) Then
            classifierIri = ClassIri(classifierId)
        ElseIf enumIriById.Exists(CStr(classifierId)) Then
            classifierIri = EnumerationIri(classifierId)
        Else
            Set classifierEl = Repository.GetElementByID(CLng(classifierId))
            If Err.Number = 0 And Not classifierEl Is Nothing Then
                classifierIri = "dafdef:ExternalClassifier_" & SafeLocal(classifierEl.Name) & "_" & ShortGuid(classifierEl.ElementGUID)
                W classifierIri & " a rdfs:Resource ; rdfs:label " & Lit(classifierEl.Name) & " ; dafm:eaGuid " & Lit(classifierEl.ElementGUID) & " ."
            End If
            Err.Clear
        End If
        If classifierIri <> "" Then W defIri & " dafm:classifier " & classifierIri & " ."
    End If
    Err.Clear
    On Error GoTo 0
    W ""
End Sub

Sub WriteShInList(enumName)
    Dim members, arr, i, line
    If Not enumMembersByName.Exists(enumName) Then Exit Sub

    members = enumMembersByName(enumName)
    If members = "" Then Exit Sub

    arr = Split(members, Chr(30))
    line = "    sh:in ("
    For i = 0 To UBound(arr)
        line = line & " " & Lit(arr(i))
    Next
    line = line & " ) ;"
    W line
End Sub

' ---------------------------------------------------------------------------
' Methods/operations (preserved if the M3 model uses them)
' ---------------------------------------------------------------------------

Sub ExportMethods(el)
    Dim m, methodIri, p, paramIri, idx
    On Error Resume Next

    For Each m In el.Methods
        methodIri = "dafdef:Operation_" & ClassLocal(el.ElementID) & "__" & SafeLocal(m.Name) & "_" & ShortGuid(m.MethodGUID)
        W methodIri
        W "    a dafm:OperationDefinition ;"
        W "    rdfs:label " & Lit(m.Name) & " ;"
        W "    dafm:eaGuid " & Lit(m.MethodGUID) & " ;"
        If m.ReturnType <> "" Then W "    dafm:returnType " & Lit(m.ReturnType) & " ;"
        If m.Visibility <> "" Then W "    dafm:visibility " & Lit(m.Visibility) & " ;"
        If m.Notes <> "" Then W "    rdfs:comment " & Lit(m.Notes) & " ;"
        W "    dafm:definedBy " & ClassIri(el.ElementID) & " ."
        W ""

        ExportTaggedValues methodIri, m.MethodGUID, m.TaggedValues, "method"
        ExportConstraints methodIri, m.MethodGUID, m.Constraints, "method"

        idx = 0
        For Each p In m.Parameters
            idx = idx + 1
            paramIri = methodIri & "_param_" & SafeLocal(p.Name) & "_" & CStr(idx)
            W paramIri
            W "    a dafm:ParameterDefinition ;"
            W "    rdfs:label " & Lit(p.Name) & " ;"
            W "    dafm:parameterType " & Lit(p.Type) & " ;"
            W "    dafm:parameterPosition " & CStr(idx) & " ;"
            If p.Default <> "" Then W "    dafm:defaultValue " & Lit(p.Default) & " ;"
            If p.Notes <> "" Then W "    rdfs:comment " & Lit(p.Notes) & " ;"
            W "    dafm:definedBy " & methodIri & " ."
            W ""
            ExportTaggedValues paramIri, methodIri & "_" & CStr(idx), p.TaggedValues, "parameter"
        Next
    Next

    Err.Clear
    On Error GoTo 0
End Sub

' ---------------------------------------------------------------------------
' Relationship export pass
' ---------------------------------------------------------------------------

Sub ExportRelationships(pkg)
    Dim el, subPkg, c

    For Each el In pkg.Elements
        If LCase(el.Type) = "class" Then
            For Each c In el.Connectors
                ' Export once, from EA Client/source. Generalization is handled above.
                ' EA NoteLink connectors are documentation/diagram links and are not DAF semantic relationships.
                If c.ClientID = el.ElementID And LCase(c.Type) <> "generalization" Then
                    If Not IsIgnoredRelationshipConnector(c) Then
                        ExportRelationship c
                    End If
                End If
            Next
        End If
    Next

    For Each subPkg In pkg.Packages
        ExportRelationships subPkg
    Next
End Sub

Sub ExportRelationship(c)
    Dim sourceEl, targetEl, sourceIri, targetIri, sourceLocal, targetLocal
    Dim relLocal, relClassIri, predIri, inversePredIri
    Dim metaclassName, redefinesName, refinesName, forwardRole, backwardRole
    Dim relationshipKind, relationshipKindSource, sourceEndIri, targetEndIri

    ' Defensive guard: NoteLink connectors must never become semantic relationships.
    If IsIgnoredRelationshipConnector(c) Then Exit Sub

    If Not classIriById.Exists(CStr(c.ClientID)) Then
        Warn "Skipping connector " & c.ConnectorGUID & ": source " & HumanReadableElementLabel(c.ClientID) & " is not a registered M3 class."
        Exit Sub
    End If

    If Not classIriById.Exists(CStr(c.SupplierID)) Then
        Warn "Skipping connector " & c.ConnectorGUID & ": target " & HumanReadableElementLabel(c.SupplierID) & " is not a registered M3 class."
        Exit Sub
    End If

    Set sourceEl = Repository.GetElementByID(c.ClientID)
    Set targetEl = Repository.GetElementByID(c.SupplierID)

    sourceIri = ClassIri(c.ClientID)
    targetIri = ClassIri(c.SupplierID)
    sourceLocal = ClassLocal(c.ClientID)
    targetLocal = ClassLocal(c.SupplierID)

    relLocal = RelationshipLocal(c, sourceLocal, targetLocal)
    relClassIri = "dafrel:" & relLocal
    predIri = "dafpred:" & relLocal
    inversePredIri = "dafpred:" & relLocal & "_inverse"

    metaclassName = GetTaggedValue(c, "Metaclass")
    redefinesName = GetTaggedValue(c, "Redefines")
    refinesName = GetTaggedValue(c, "Refines")
    forwardRole = SafeConnectorEndRole(c.SupplierEnd)
    backwardRole = SafeConnectorEndRole(c.ClientEnd)

    If metaclassName <> "" Then
        relationshipKind = metaclassName
        relationshipKindSource = "Metaclass"
    ElseIf redefinesName <> "" Then
        relationshipKind = c.Type
        relationshipKindSource = "Redefines"
    Else
        relationshipKind = c.Type
        relationshipKindSource = "EAConnectorTypeFallback"
        Warn "Relationship '" & RelationshipLabel(c, sourceEl, targetEl) & "' from " & HumanReadableElementLabel(c.ClientID) & " to " & HumanReadableElementLabel(c.SupplierID) & " has no Metaclass or Redefines tag. Using EA connector type '" & c.Type & "' as relationship kind."
    End If

    relationshipCount = relationshipCount + 1
    If Not generatedRelationshipGuids.Exists(LCase(c.ConnectorGUID)) Then generatedRelationshipGuids.Add LCase(c.ConnectorGUID), relClassIri
    If Not generatedRelationshipLabels.Exists(LCase(c.ConnectorGUID)) Then generatedRelationshipLabels.Add LCase(c.ConnectorGUID), RelationshipLabel(c, sourceEl, targetEl)

    W "# Relationship: " & RelationshipLabel(c, sourceEl, targetEl)
    W relClassIri
    W "    a owl:Class, dafm:RelationshipType ;"
    W "    rdfs:subClassOf dafm:Relationship ;"
    W "    rdfs:label " & Lit(HumanReadableRelationshipName(c, sourceEl, targetEl)) & " ;"
    If Trim(c.Name) <> "" Then W "    skos:notation " & Lit(c.Name) & " ;"
    W "    dafm:eaGuid " & Lit(c.ConnectorGUID) & " ;"
    W "    dafm:sourceClass " & sourceIri & " ;"
    W "    dafm:targetClass " & targetIri & " ;"
    W "    dafm:projectionPredicate " & predIri & " ;"
    W "    dafm:inversePredicate " & inversePredIri & " ;"
    W "    dafm:relationshipKind " & Lit(relationshipKind) & " ;"
    W "    dafm:relationshipKindSource " & Lit(relationshipKindSource) & RelationshipMetadataTail(c, forwardRole, backwardRole, redefinesName, refinesName)
    W ""
    W relClassIri & " dafm:sourceConnectorType " & Lit(c.Type) & " ."
    On Error Resume Next
    If c.Direction <> "" Then W relClassIri & " dafm:sourceDirection " & Lit(c.Direction) & " ."
    If c.Stereotype <> "" Then W relClassIri & " dafm:sourceStereotype " & Lit(c.Stereotype) & " ."
    Err.Clear
    On Error GoTo 0
    W ""

    ' Direct graph projection used by SPARQL/MCP traversal.
    W predIri
    W "    a owl:ObjectProperty ;"
    W "    rdfs:domain " & sourceIri & " ;"
    W "    rdfs:range " & targetIri & " ;"
    W "    owl:inverseOf " & inversePredIri & " ;"
    W "    rdfs:label " & Lit(ForwardPredicateLabel(c, forwardRole)) & " ."
    W ""

    W inversePredIri
    W "    a owl:ObjectProperty ;"
    W "    rdfs:domain " & targetIri & " ;"
    W "    rdfs:range " & sourceIri & " ;"
    W "    owl:inverseOf " & predIri & " ;"
    W "    rdfs:label " & Lit(BackwardPredicateLabel(c, backwardRole)) & " ."
    W ""

    sourceEndIri = "dafdef:RelationshipEnd_" & relLocal & "_source"
    targetEndIri = "dafdef:RelationshipEnd_" & relLocal & "_target"

    W relClassIri & " dafm:sourceEnd " & sourceEndIri & " ; dafm:targetEnd " & targetEndIri & " ."
    W ""
    ExportRelationshipEnd sourceEndIri, c.ClientEnd, "source", sourceIri, relLocal
    ExportRelationshipEnd targetEndIri, c.SupplierEnd, "target", targetIri, relLocal

    ExportTaggedValues relClassIri, c.ConnectorGUID, c.TaggedValues, "connector"
    ExportConstraints relClassIri, c.ConnectorGUID, c.Constraints, "connector"

    WriteRelationshipInstanceShape relLocal, relClassIri, sourceIri, targetIri

    ' Constraints on projected triples:
    ' SupplierEnd multiplicity constrains how many targets each source may have.
    WriteProjectedForwardShape sourceLocal, predIri, targetIri, c.SupplierEnd.Cardinality, relLocal

    ' ClientEnd multiplicity constrains how many sources each target may have.
    WriteProjectedInverseShape targetLocal, predIri, sourceIri, c.ClientEnd.Cardinality, relLocal
End Sub

Function RelationshipMetadataTail(c, forwardRole, backwardRole, redefinesName, refinesName)
    Dim s
    s = ""

    If c.Alias <> "" And Trim(c.Name) <> "" And LCase(Trim(c.Alias)) <> LCase(Trim(c.Name)) Then s = s & " ;" & vbCrLf & "    skos:altLabel " & Lit(c.Name)
    If c.Notes <> "" Then s = s & " ;" & vbCrLf & "    rdfs:comment " & Lit(c.Notes)
    If forwardRole <> "" Then s = s & " ;" & vbCrLf & "    dafm:forwardRole " & Lit(forwardRole)
    If backwardRole <> "" Then s = s & " ;" & vbCrLf & "    dafm:backwardRole " & Lit(backwardRole)
    If redefinesName <> "" Then s = s & " ;" & vbCrLf & "    dafm:redefines " & Lit(redefinesName)
    If refinesName <> "" Then s = s & " ;" & vbCrLf & "    dafm:refines " & Lit(refinesName)

    If c.SupplierEnd.Cardinality <> "" Then
        s = s & " ;" & vbCrLf & "    dafm:targetMultiplicity " & Lit(c.SupplierEnd.Cardinality)
    End If
    If c.ClientEnd.Cardinality <> "" Then
        s = s & " ;" & vbCrLf & "    dafm:sourceMultiplicity " & Lit(c.ClientEnd.Cardinality)
    End If

    s = s & " ."
    RelationshipMetadataTail = s
End Function

Sub ExportRelationshipEnd(endIri, e, endKind, classIri, relLocal)
    Dim agg
    agg = AggregationName(SafeEndAggregation(e))

    W endIri
    W "    a dafm:RelationshipEnd ;"
    W "    dafm:endKind " & Lit(endKind) & " ;"
    W "    dafm:endClass " & classIri & " ;"
    W "    dafm:cardinality " & Lit(SafeEndCardinality(e)) & " ;"
    W "    dafm:aggregation " & Lit(agg) & RelationshipEndTail(e)
    W ""

    ExportTaggedValues endIri, relLocal & "_" & endKind, e.TaggedValues, "relationshipEnd"
End Sub

Function RelationshipEndTail(e)
    Dim s, roleName, navigable, constraintText, containmentText, qualifierText
    Dim roleNote, visibilityText, stereotypeText

    s = ""
    roleName = SafeConnectorEndRole(e)
    navigable = SafeEndNavigable(e)
    constraintText = SafeEndConstraint(e)
    containmentText = SafeEndContainment(e)
    qualifierText = SafeEndQualifier(e)
    roleNote = SafeEndRoleNote(e)
    visibilityText = SafeEndVisibility(e)
    stereotypeText = SafeEndStereotype(e)

    If roleName <> "" Then s = s & " ;" & vbCrLf & "    dafm:role " & Lit(roleName)
    If navigable <> "" Then s = s & " ;" & vbCrLf & "    dafm:navigable " & Lit(navigable)
    If constraintText <> "" Then s = s & " ;" & vbCrLf & "    dafm:endConstraint " & Lit(constraintText)
    If containmentText <> "" Then s = s & " ;" & vbCrLf & "    dafm:containment " & Lit(containmentText)
    If qualifierText <> "" Then s = s & " ;" & vbCrLf & "    dafm:qualifier " & Lit(qualifierText)
    If roleNote <> "" Then s = s & " ;" & vbCrLf & "    dafm:roleNote " & Lit(roleNote)
    If visibilityText <> "" Then s = s & " ;" & vbCrLf & "    dafm:visibility " & Lit(visibilityText)
    If stereotypeText <> "" Then s = s & " ;" & vbCrLf & "    dafm:stereotype " & Lit(stereotypeText)
    If SafeEndAlias(e) <> "" Then s = s & " ;" & vbCrLf & "    dafm:endAlias " & Lit(SafeEndAlias(e))
    If SafeEndIsChangeable(e) <> "" Then s = s & " ;" & vbCrLf & "    dafm:isChangeable " & Lit(SafeEndIsChangeable(e))
    If SafeEndRoleType(e) <> "" Then s = s & " ;" & vbCrLf & "    dafm:roleType " & Lit(SafeEndRoleType(e))

    s = s & " ;" & vbCrLf & "    dafm:isDerived " & BoolLit(SafeEndDerived(e))
    s = s & " ;" & vbCrLf & "    dafm:derivedUnion " & BoolLit(SafeEndDerivedUnion(e))
    s = s & " ;" & vbCrLf & "    dafm:allowDuplicates " & BoolLit(SafeEndAllowDuplicates(e))
    s = s & " ;" & vbCrLf & "    dafm:ownedByClassifier " & BoolLit(SafeEndOwnedByClassifier(e))
    s = s & " ;" & vbCrLf & "    dafm:ordering " & CStr(SafeEndOrdering(e))
    s = s & " ."
    RelationshipEndTail = s
End Function

Sub WriteRelationshipInstanceShape(relLocal, relClassIri, sourceIri, targetIri)
    W "dafshape:" & relLocal & "RelationshipShape"
    W "    a sh:NodeShape ;"
    W "    sh:targetClass " & relClassIri & " ;"
    W "    sh:node dafshape:RelationshipShape ;"
    W "    sh:property [ sh:path dafm:source ; sh:minCount 1 ; sh:maxCount 1 ; sh:class " & sourceIri & " ] ;"
    W "    sh:property [ sh:path dafm:target ; sh:minCount 1 ; sh:maxCount 1 ; sh:class " & targetIri & " ] ."
    W ""
End Sub

Sub WriteProjectedForwardShape(sourceLocal, predIri, targetIri, cardinality, relLocal)
    W "dafshape:" & sourceLocal & "Shape sh:property ["
    W "    sh:path " & predIri & " ;"
    W "    sh:class " & targetIri & " ;"
    WriteCardinality cardinality
    W "    sh:name " & Lit(relLocal)
    W "] ."
    W ""
End Sub

Sub WriteProjectedInverseShape(targetLocal, predIri, sourceIri, cardinality, relLocal)
    W "dafshape:" & targetLocal & "Shape sh:property ["
    W "    sh:path [ sh:inversePath " & predIri & " ] ;"
    W "    sh:class " & sourceIri & " ;"
    WriteCardinality cardinality
    W "    sh:name " & Lit("inverse " & relLocal)
    W "] ."
    W ""
End Sub

Sub WriteCardinality(cardinality)
    Dim minC, maxC
    If Trim(cardinality) = "" Then Exit Sub

    minC = ParseMinCardinality(cardinality)
    maxC = ParseMaxCardinality(cardinality)

    If minC >= 0 Then W "    sh:minCount " & CStr(minC) & " ;"
    If maxC >= 0 Then W "    sh:maxCount " & CStr(maxC) & " ;"
End Sub

Sub WriteMinMaxCount(lowerBound, upperBound)
    Dim minC, maxC

    If Trim(lowerBound) <> "" Then
        minC = ParseMinCardinality(lowerBound)
        If minC >= 0 Then W "    sh:minCount " & CStr(minC) & " ;"
    End If

    If Trim(upperBound) <> "" Then
        maxC = ParseMaxCardinality(upperBound)
        If maxC >= 0 Then W "    sh:maxCount " & CStr(maxC) & " ;"
    End If
End Sub

' ---------------------------------------------------------------------------
' Generic metadata, tagged values and constraints
' ---------------------------------------------------------------------------

Sub ExportElementCommonMetadata(subjectIri, el)
    Dim s

    ' These statements preserve the common source metadata of the M2 definition.
    If el.Status <> "" Then W subjectIri & " dafm:sourceStatus " & Lit(el.Status) & " ."
    If el.Version <> "" Then W subjectIri & " dafm:sourceVersion " & Lit(el.Version) & " ."
    If el.Phase <> "" Then W subjectIri & " dafm:sourcePhase " & Lit(el.Phase) & " ."
    If el.Author <> "" Then W subjectIri & " dcterms:creator " & Lit(el.Author) & " ."
    If el.Stereotype <> "" Then W subjectIri & " dafm:sourceStereotype " & Lit(el.Stereotype) & " ."
    If el.Type <> "" Then W subjectIri & " dafm:sourceModelType " & Lit(el.Type) & " ."

    On Error Resume Next
    s = el.Visibility
    If Err.Number = 0 And s <> "" Then W subjectIri & " dafm:sourceVisibility " & Lit(s) & " ."
    Err.Clear

    s = el.Keywords
    If Err.Number = 0 And s <> "" Then W subjectIri & " dcterms:subject " & Lit(s) & " ."
    Err.Clear

    s = el.Complexity
    If Err.Number = 0 And s <> "" Then W subjectIri & " dafm:sourceComplexity " & Lit(s) & " ."
    Err.Clear

    s = el.Multiplicity
    If Err.Number = 0 And s <> "" Then W subjectIri & " dafm:sourceMultiplicity " & Lit(s) & " ."
    Err.Clear

    s = el.Persistence
    If Err.Number = 0 And s <> "" Then W subjectIri & " dafm:sourcePersistence " & Lit(s) & " ."
    Err.Clear

    s = el.Priority
    If Err.Number = 0 And s <> "" Then W subjectIri & " dafm:sourcePriority " & Lit(s) & " ."
    Err.Clear

    s = el.GenType
    If Err.Number = 0 And s <> "" Then W subjectIri & " dafm:sourceLanguage " & Lit(s) & " ."
    Err.Clear

    W subjectIri & " dcterms:created " & TypedLit(IsoDateTime(el.Created), "xsd:dateTime") & " ."
    W subjectIri & " dcterms:modified " & TypedLit(IsoDateTime(el.Modified), "xsd:dateTime") & " ."
    On Error GoTo 0
    W ""
End Sub

Sub ExportTaggedValues(ownerIri, ownerGuid, collection, ownerKind)
    Dim tv, i, tagIri, tagName, tagValue, tagNotes
    i = 0

    On Error Resume Next
    For Each tv In collection
        i = i + 1
        tagName = SafeTagName(tv)
        tagValue = SafeTagValue(tv)
        tagNotes = SafeTagNotes(tv)

        tagIri = "dafdef:TaggedValue_" & SafeLocal(ownerGuid) & "_" & SafeLocal(tagName) & "_" & CStr(i)

        W ownerIri & " dafm:hasTaggedValue " & tagIri & " ."
        W tagIri
        W "    a dafm:TaggedValue ;"
        W "    dafm:tagName " & Lit(tagName) & " ;"
        W "    dafm:tagValue " & Lit(tagValue) & " ;"
        W "    dafm:ownerKind " & Lit(ownerKind) & TaggedValueTail(tagNotes)
        W ""

        taggedValueCount = taggedValueCount + 1
    Next
    Err.Clear
    On Error GoTo 0
End Sub

Function TaggedValueTail(notesText)
    If notesText <> "" Then
        TaggedValueTail = " ;" & vbCrLf & "    dafm:tagNotes " & Lit(notesText) & " ."
    Else
        TaggedValueTail = " ."
    End If
End Function

Sub ExportConstraints(ownerIri, ownerGuid, collection, ownerKind)
    Dim con, i, conIri, n, t, body, statusText
    i = 0

    On Error Resume Next
    For Each con In collection
        i = i + 1
        n = ""
        t = ""
        body = ""
        statusText = ""
        n = con.Name
        t = con.Type
        body = con.Notes
        statusText = con.Status

        conIri = "dafdef:Constraint_" & SafeLocal(ownerGuid) & "_" & SafeLocal(n) & "_" & CStr(i)

        W ownerIri & " dafm:hasConstraint " & conIri & " ."
        W conIri
        W "    a dafm:Constraint ;"
        W "    dafm:constraintName " & Lit(n) & " ;"
        W "    dafm:constraintType " & Lit(t) & " ;"
        W "    dafm:constraintBody " & Lit(body) & " ;"
        W "    dafm:ownerKind " & Lit(ownerKind) & ConstraintTail(statusText)
        W ""

        constraintCount = constraintCount + 1
    Next
    Err.Clear
    On Error GoTo 0
End Sub

Function ConstraintTail(statusText)
    If statusText <> "" Then
        ConstraintTail = " ;" & vbCrLf & "    dafm:constraintStatus " & Lit(statusText) & " ."
    Else
        ConstraintTail = " ."
    End If
End Function

' ---------------------------------------------------------------------------
' Helper definitions in generated RDF
' ---------------------------------------------------------------------------

Sub ClassDef(iri, label, comment)
    W iri
    W "    a owl:Class ;"
    W "    rdfs:label " & Lit(label) & " ;"
    W "    rdfs:comment " & Lit(comment) & " ."
    W ""
End Sub

Sub ObjectPropDef(iri, label, comment)
    W iri
    W "    a owl:ObjectProperty ;"
    W "    rdfs:label " & Lit(label) & " ;"
    W "    rdfs:comment " & Lit(comment) & " ."
    W ""
End Sub

Sub DataPropDef(iri, label, comment, rangeIri)
    W iri
    W "    a owl:DatatypeProperty ;"
    W "    rdfs:label " & Lit(label) & " ;"
    W "    rdfs:comment " & Lit(comment) & " ;"
    W "    rdfs:range " & rangeIri & " ."
    W ""
End Sub

Sub CommonProp(localName, label, comment, rangeIri)
    W "dafp:" & localName
    W "    a owl:DatatypeProperty ;"
    W "    rdfs:domain dafm:ModelElement ;"
    W "    rdfs:range " & rangeIri & " ;"
    W "    rdfs:label " & Lit(label) & " ;"
    W "    rdfs:comment " & Lit(comment) & " ."
    W ""
End Sub

Sub CommonBoolProp(localName, label, comment)
    CommonProp localName, label, comment, "xsd:boolean"
End Sub

' ---------------------------------------------------------------------------
' Name/IRI helpers
' ---------------------------------------------------------------------------

Function HumanReadableElementLabel(elementId)
    Dim el, displayName, internalName, aliasName, label

    Set el = Nothing
    On Error Resume Next
    Set el = Repository.GetElementByID(CLng(elementId))
    If Err.Number <> 0 Or el Is Nothing Then
        Err.Clear
        On Error GoTo 0
        HumanReadableElementLabel = "[ElementID=" & CStr(elementId) & "]"
        Exit Function
    End If
    Err.Clear

    internalName = Trim(CStr(el.Name))
    aliasName = Trim(CStr(el.Alias))

    ' DAF uses Alias as the human-readable metatype where available.
    If aliasName <> "" Then
        displayName = aliasName
    ElseIf internalName <> "" Then
        displayName = internalName
    Else
        displayName = "Unnamed element"
    End If

    label = "'" & displayName & "'"
    If internalName <> "" And LCase(internalName) <> LCase(displayName) Then
        label = label & " (DAF name: '" & internalName & "')"
    End If

    If el.ElementGUID <> "" Then
        label = label & " [GUID=" & el.ElementGUID & ", ElementID=" & CStr(elementId) & "]"
    Else
        label = label & " [ElementID=" & CStr(elementId) & "]"
    End If

    On Error GoTo 0
    HumanReadableElementLabel = label
End Function


Function ConceptIri(elementId)
    If conceptIriById.Exists(CStr(elementId)) Then
        ConceptIri = conceptIriById(CStr(elementId))
    Else
        ConceptIri = "dafdef:UnresolvedConcept_" & CStr(elementId)
    End If
End Function

Function ConceptLocal(elementId)
    If conceptLocalById.Exists(CStr(elementId)) Then
        ConceptLocal = conceptLocalById(CStr(elementId))
    Else
        ConceptLocal = "UnresolvedConcept_" & CStr(elementId)
    End If
End Function

Function ClassIri(elementId)
    If classIriById.Exists(CStr(elementId)) Then
        ClassIri = classIriById(CStr(elementId))
    Else
        ClassIri = "dafdef:UnresolvedClass_" & CStr(elementId)
    End If
End Function

Function ClassLocal(elementId)
    If classLocalById.Exists(CStr(elementId)) Then
        ClassLocal = classLocalById(CStr(elementId))
    Else
        ClassLocal = "UnresolvedClass_" & CStr(elementId)
    End If
End Function

Function EnumerationIri(elementId)
    If enumIriById.Exists(CStr(elementId)) Then
        EnumerationIri = enumIriById(CStr(elementId))
    Else
        EnumerationIri = "dafenum:UnresolvedEnumeration_" & CStr(elementId)
    End If
End Function

Function HumanReadableName(el)
    Dim s
    s = Trim(CStr(el.Alias))
    If s = "" Then s = Trim(CStr(el.Name))
    If s = "" Then s = "Unnamed M3 class"
    HumanReadableName = s
End Function

Function IsIgnoredRelationshipConnector(c)
    Dim connectorType
    connectorType = LCase(Trim(CStr(c.Type)))
    IsIgnoredRelationshipConnector = (connectorType = "notelink")
End Function

Function HumanReadableRelationshipName(c, sourceEl, targetEl)
    Dim s
    s = Trim(CStr(c.Alias))
    If s = "" Then s = Trim(CStr(c.Name))
    If s = "" Then s = Trim(SafeConnectorEndRole(c.SupplierEnd))
    If s = "" Then s = HumanReadableName(sourceEl) & " " & c.Type & " " & HumanReadableName(targetEl)
    HumanReadableRelationshipName = s
End Function

Function RelationshipRegistrationLabel(c)
    Dim sourceEl, targetEl
    Set sourceEl = Nothing
    Set targetEl = Nothing
    On Error Resume Next
    Set sourceEl = Repository.GetElementByID(c.ClientID)
    Set targetEl = Repository.GetElementByID(c.SupplierID)
    Err.Clear
    On Error GoTo 0
    If sourceEl Is Nothing Or targetEl Is Nothing Then
        RelationshipRegistrationLabel = "connector " & c.ConnectorGUID
    Else
        RelationshipRegistrationLabel = "'" & HumanReadableRelationshipName(c, sourceEl, targetEl) & "' from " & HumanReadableElementLabel(c.ClientID) & " to " & HumanReadableElementLabel(c.SupplierID)
    End If
End Function

Function GuidLocal(guid)
    Dim s
    s = Replace(CStr(guid), "{", "")
    s = Replace(s, "}", "")
    s = Replace(s, "-", "")
    If s = "" Then s = "noguid"
    GuidLocal = SafeLocal(s)
End Function

Function StableIdentityLocal(guid, fallbackLocal)
    If Trim(CStr(guid)) <> "" Then
        StableIdentityLocal = GuidLocal(guid)
    Else
        StableIdentityLocal = SafeLocal(fallbackLocal)
        Warn "Source object has no GUID. Falling back to readable RDF identity '" & StableIdentityLocal & "'."
    End If
End Function

Function UniquePropertyLocal(baseLocal, guid)
    Dim localName, key
    localName = baseLocal
    key = LCase(localName)
    If usedPropertyLocals.Exists(key) Then
        localName = baseLocal & "_" & ShortGuid(guid)
        Warn "Duplicate property projection local name '" & baseLocal & "'. Using " & localName & " for attribute " & guid
    End If
    usedPropertyLocals.Add LCase(localName), True
    UniquePropertyLocal = localName
End Function

Function RelationshipLocal(c, sourceLocal, targetLocal)
    Dim baseLocal, localName, key, rawName

    rawName = Trim(c.Name)
    If rawName = "" Then
        rawName = sourceLocal & "_" & c.Type & "_" & targetLocal
    End If

    baseLocal = SafeLocal(rawName)
    localName = baseLocal
    key = LCase(localName)

    If usedRelationshipLocals.Exists(key) Then
        localName = baseLocal & "_" & ShortGuid(c.ConnectorGUID)
        Warn "Duplicate relationship name '" & baseLocal & "'. Using " & localName & " for " & c.ConnectorGUID
    End If

    usedRelationshipLocals.Add LCase(localName), True
    RelationshipLocal = localName
End Function

Function RelationshipLabel(c, sourceEl, targetEl)
    If Trim(c.Name) <> "" Then
        RelationshipLabel = c.Name
    ElseIf Trim(c.SupplierEnd.Role) <> "" Then
        RelationshipLabel = c.SupplierEnd.Role
    Else
        RelationshipLabel = sourceEl.Name & " " & c.Type & " " & targetEl.Name
    End If
End Function

Function ForwardPredicateLabel(c, forwardRole)
    If forwardRole <> "" Then
        ForwardPredicateLabel = forwardRole
    Else
        ForwardPredicateLabel = RelationshipLabel(c, Repository.GetElementByID(c.ClientID), Repository.GetElementByID(c.SupplierID))
    End If
End Function

Function BackwardPredicateLabel(c, backwardRole)
    If backwardRole <> "" Then
        BackwardPredicateLabel = backwardRole
    Else
        BackwardPredicateLabel = "inverse of " & RelationshipLabel(c, Repository.GetElementByID(c.ClientID), Repository.GetElementByID(c.SupplierID))
    End If
End Function

Function PackageIri(pkg)
    PackageIri = "dafpkg:Package_" & SafeLocal(ShortGuid(pkg.PackageGUID))
End Function

Function SafeLocal(value)
    Dim i, ch, code, out
    out = ""

    value = CStr(value)
    For i = 1 To Len(value)
        ch = Mid(value, i, 1)
        code = AscW(ch)
        If (code >= 48 And code <= 57) Or (code >= 65 And code <= 90) Or (code >= 97 And code <= 122) Or ch = "_" Then
            out = out & ch
        Else
            out = out & "_"
        End If
    Next

    Do While InStr(out, "__") > 0
        out = Replace(out, "__", "_")
    Loop

    If out = "" Then out = "unnamed"

    ch = Left(out, 1)
    If ch >= "0" And ch <= "9" Then out = "n_" & out

    SafeLocal = out
End Function

Function ShortGuid(guid)
    Dim s
    s = Replace(CStr(guid), "{", "")
    s = Replace(s, "}", "")
    s = Replace(s, "-", "")
    If Len(s) > 8 Then s = Left(s, 8)
    If s = "" Then s = "noguid"
    ShortGuid = s
End Function

' ---------------------------------------------------------------------------
' Literal/date/path helpers
' ---------------------------------------------------------------------------

Function Lit(value)
    Lit = Chr(34) & EscapeTurtle(CStr(value)) & Chr(34)
End Function

Function TypedLit(value, datatypeIri)
    TypedLit = Lit(value) & "^^" & datatypeIri
End Function

Function BoolLit(value)
    If CBool(value) Then
        BoolLit = "true"
    Else
        BoolLit = "false"
    End If
End Function

Function EscapeTurtle(value)
    Dim s
    s = CStr(value)
    s = Replace(s, "\", "\\")
    s = Replace(s, Chr(34), "\" & Chr(34))
    s = Replace(s, vbCrLf, "\n")
    s = Replace(s, vbCr, "\n")
    s = Replace(s, vbLf, "\n")
    s = Replace(s, vbTab, "\t")
    EscapeTurtle = s
End Function

Function IsoDateTime(value)
    On Error Resume Next
    IsoDateTime = FourDigits(Year(value)) & "-" & TwoDigits(Month(value)) & "-" & TwoDigits(Day(value)) & "T" & _
                  TwoDigits(Hour(value)) & ":" & TwoDigits(Minute(value)) & ":" & TwoDigits(Second(value))
    If Err.Number <> 0 Then
        Err.Clear
        IsoDateTime = "1970-01-01T00:00:00"
    End If
    On Error GoTo 0
End Function

Function TwoDigits(n)
    TwoDigits = Right("0" & CStr(n), 2)
End Function

Function FourDigits(n)
    FourDigits = Right("0000" & CStr(n), 4)
End Function

Function JoinPath(folder, filename)
    If Right(folder, 1) = "\" Or Right(folder, 1) = "/" Then
        JoinPath = folder & filename
    Else
        JoinPath = folder & "\" & filename
    End If
End Function

Sub EnsureFolder(path)
    Dim parent
    If fso.FolderExists(path) Then Exit Sub

    parent = fso.GetParentFolderName(path)
    If parent <> "" And Not fso.FolderExists(parent) Then
        EnsureFolder parent
    End If

    If Not fso.FolderExists(path) Then fso.CreateFolder path
End Sub

Function GetPackagePath(pkg)
    Dim currentPkg, pathText
    Set currentPkg = pkg
    pathText = currentPkg.Name

    Do While currentPkg.ParentID <> 0
        On Error Resume Next
        Set currentPkg = Repository.GetPackageByID(currentPkg.ParentID)
        If Err.Number <> 0 Or currentPkg Is Nothing Then
            Err.Clear
            Exit Do
        End If
        On Error GoTo 0
        pathText = currentPkg.Name & "/" & pathText
    Loop

    GetPackagePath = pathText
End Function

' ---------------------------------------------------------------------------
' Datatypes/cardinality
' ---------------------------------------------------------------------------

Function MapDatatype(typeName)
    Dim t
    t = LCase(Trim(typeName))

    Select Case t
        Case "int", "integer", "long", "short", "byte"
            MapDatatype = "xsd:integer"
        Case "float", "double", "real", "decimal", "number"
            MapDatatype = "xsd:decimal"
        Case "bool", "boolean"
            MapDatatype = "xsd:boolean"
        Case "date"
            MapDatatype = "xsd:date"
        Case "datetime", "date-time", "timestamp"
            MapDatatype = "xsd:dateTime"
        Case "time"
            MapDatatype = "xsd:time"
        Case "uri", "url", "anyuri"
            MapDatatype = "xsd:anyURI"
        Case Else
            MapDatatype = "xsd:string"
    End Select
End Function

Function ParseMinCardinality(cardinality)
    Dim s, parts
    s = Trim(CStr(cardinality))

    If s = "" Then
        ParseMinCardinality = -1
        Exit Function
    End If

    If s = "*" Then
        ParseMinCardinality = 0
        Exit Function
    End If

    If InStr(s, "..") > 0 Then
        parts = Split(s, "..")
        If IsNumeric(parts(0)) Then
            ParseMinCardinality = CLng(parts(0))
        Else
            ParseMinCardinality = -1
        End If
    ElseIf IsNumeric(s) Then
        ParseMinCardinality = CLng(s)
    Else
        ParseMinCardinality = -1
    End If
End Function

Function ParseMaxCardinality(cardinality)
    Dim s, parts, maxPart
    s = Trim(CStr(cardinality))

    If s = "" Or s = "*" Then
        ParseMaxCardinality = -1
        Exit Function
    End If

    If InStr(s, "..") > 0 Then
        parts = Split(s, "..")
        maxPart = Trim(parts(1))
        If maxPart = "*" Then
            ParseMaxCardinality = -1
        ElseIf IsNumeric(maxPart) Then
            ParseMaxCardinality = CLng(maxPart)
        Else
            ParseMaxCardinality = -1
        End If
    ElseIf IsNumeric(s) Then
        ParseMaxCardinality = CLng(s)
    Else
        ParseMaxCardinality = -1
    End If
End Function

Function AggregationName(value)
    Select Case CLng(value)
        Case 1
            AggregationName = "Shared"
        Case 2
            AggregationName = "Composite"
        Case Else
            AggregationName = "None"
    End Select
End Function

' ---------------------------------------------------------------------------
' Safe EA Automation getters
' ---------------------------------------------------------------------------

Function GetTaggedValue(owner, tagName)
    Dim tv
    GetTaggedValue = ""

    On Error Resume Next
    For Each tv In owner.TaggedValues
        If LCase(SafeTagName(tv)) = LCase(tagName) Then
            GetTaggedValue = SafeTagValue(tv)
            Exit Function
        End If
    Next
    Err.Clear
    On Error GoTo 0
End Function

Function SafeTagName(tv)
    Dim s
    s = ""
    On Error Resume Next
    s = tv.Name
    If Err.Number <> 0 Or s = "" Then
        Err.Clear
        s = tv.Tag
    End If
    Err.Clear
    On Error GoTo 0
    SafeTagName = CStr(s)
End Function

Function SafeTagValue(tv)
    Dim s
    s = ""
    On Error Resume Next
    s = tv.Value
    Err.Clear
    On Error GoTo 0
    SafeTagValue = CStr(s)
End Function

Function SafeTagNotes(tv)
    Dim s
    s = ""
    On Error Resume Next
    s = tv.Notes
    Err.Clear
    On Error GoTo 0
    SafeTagNotes = CStr(s)
End Function

Function SafeAttributeLowerBound(a)
    Dim s
    s = ""
    On Error Resume Next
    s = a.LowerBound
    Err.Clear
    On Error GoTo 0
    SafeAttributeLowerBound = CStr(s)
End Function

Function SafeAttributeUpperBound(a)
    Dim s
    s = ""
    On Error Resume Next
    s = a.UpperBound
    Err.Clear
    On Error GoTo 0
    SafeAttributeUpperBound = CStr(s)
End Function

Function SafeAttributeDefault(a)
    Dim s
    s = ""
    On Error Resume Next
    s = a.Default
    Err.Clear
    On Error GoTo 0
    SafeAttributeDefault = CStr(s)
End Function

Function SafeConnectorEndRole(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.Role
    Err.Clear
    On Error GoTo 0
    SafeConnectorEndRole = CStr(s)
End Function

Function SafeEndAlias(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.Alias
    Err.Clear
    On Error GoTo 0
    SafeEndAlias = CStr(s)
End Function

Function SafeEndAllowDuplicates(e)
    Dim b
    b = False
    On Error Resume Next
    b = e.AllowDuplicates
    If Err.Number <> 0 Then b = False
    Err.Clear
    On Error GoTo 0
    SafeEndAllowDuplicates = CBool(b)
End Function

Function SafeEndDerivedUnion(e)
    Dim b
    b = False
    On Error Resume Next
    b = e.DerivedUnion
    If Err.Number <> 0 Then b = False
    Err.Clear
    On Error GoTo 0
    SafeEndDerivedUnion = CBool(b)
End Function

Function SafeEndIsChangeable(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.IsChangeable
    Err.Clear
    On Error GoTo 0
    SafeEndIsChangeable = CStr(s)
End Function

Function SafeEndOrdering(e)
    Dim v
    v = 0
    On Error Resume Next
    v = e.Ordering
    If Err.Number <> 0 Then v = 0
    Err.Clear
    On Error GoTo 0
    SafeEndOrdering = CLng(v)
End Function

Function SafeEndOwnedByClassifier(e)
    Dim b
    b = False
    On Error Resume Next
    b = e.OwnedByClassifier
    If Err.Number <> 0 Then b = False
    Err.Clear
    On Error GoTo 0
    SafeEndOwnedByClassifier = CBool(b)
End Function

Function SafeEndRoleType(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.RoleType
    Err.Clear
    On Error GoTo 0
    SafeEndRoleType = CStr(s)
End Function

Function SafeEndAggregation(e)
    Dim v
    v = 0
    On Error Resume Next
    v = e.Aggregation
    If Err.Number <> 0 Then v = 0
    Err.Clear
    On Error GoTo 0
    SafeEndAggregation = CLng(v)
End Function

Function SafeEndCardinality(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.Cardinality
    Err.Clear
    On Error GoTo 0
    SafeEndCardinality = CStr(s)
End Function

Function SafeEndNavigable(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.Navigable
    Err.Clear
    On Error GoTo 0
    SafeEndNavigable = CStr(s)
End Function

Function SafeEndConstraint(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.Constraint
    Err.Clear
    On Error GoTo 0
    SafeEndConstraint = CStr(s)
End Function

Function SafeEndContainment(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.Containment
    Err.Clear
    On Error GoTo 0
    SafeEndContainment = CStr(s)
End Function

Function SafeEndQualifier(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.Qualifier
    Err.Clear
    On Error GoTo 0
    SafeEndQualifier = CStr(s)
End Function

Function SafeEndRoleNote(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.RoleNote
    Err.Clear
    On Error GoTo 0
    SafeEndRoleNote = CStr(s)
End Function

Function SafeEndVisibility(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.Visibility
    Err.Clear
    On Error GoTo 0
    SafeEndVisibility = CStr(s)
End Function

Function SafeEndStereotype(e)
    Dim s
    s = ""
    On Error Resume Next
    s = e.StereotypeEx
    If Err.Number <> 0 Or s = "" Then
        Err.Clear
        s = e.Stereotype
    End If
    Err.Clear
    On Error GoTo 0
    SafeEndStereotype = CStr(s)
End Function

Function SafeEndDerived(e)
    Dim b
    b = False
    On Error Resume Next
    b = e.Derived
    If Err.Number <> 0 Then b = False
    Err.Clear
    On Error GoTo 0
    SafeEndDerived = CBool(b)
End Function

Function SafeGetPackageNotes(pkg)
    Dim s
    s = ""
    On Error Resume Next
    s = pkg.Notes
    If Err.Number <> 0 Then
        Err.Clear
        s = pkg.Element.Notes
    End If
    Err.Clear
    On Error GoTo 0
    SafeGetPackageNotes = CStr(s)
End Function

' ---------------------------------------------------------------------------
' Report/output
' ---------------------------------------------------------------------------

Sub W(line)
    rdfStream.WriteText CStr(line) & vbCrLf
End Sub

Sub Report(line)
    reportStream.WriteText CStr(line) & vbCrLf
End Sub

Sub Warn(message)
    warningCount = warningCount + 1
    Report "WARNING: " & message
    Session.Output "WARNING: " & message
End Sub

Sub WriteGenerationSummary(pkg)
    W "# ---------------------------------------------------------------------"
    W "# Generation summary"
    W "# ---------------------------------------------------------------------"
    W ""
    W "<https://freetakteam.github.io/DAF/generation/" & SafeLocal(ShortGuid(pkg.PackageGUID)) & ">"
    W "    a dafm:GenerationRecord ;"
    W "    dcterms:created " & TypedLit(IsoDateTime(Now()), "xsd:dateTime") & " ;"
    W "    dafm:generatorVersion " & Lit(SCRIPT_VERSION) & " ;"
    W "    dafm:sourcePackageGuid " & Lit(pkg.PackageGUID) & " ;"
    W "    dafm:conceptCount " & CStr(conceptCount) & " ;"
    W "    dafm:supportingClassCount " & CStr(supportingClassCount) & " ;"
    W "    dafm:registeredClassCount " & CStr(registeredClassGuids.Count) & " ;"
    W "    dafm:enumerationCount " & CStr(enumCount) & " ;"
    W "    dafm:propertyCount " & CStr(attributeCount) & " ;"
    W "    dafm:relationshipCount " & CStr(relationshipCount) & " ;"
    W "    dafm:ignoredNoteLinkCount " & CStr(ignoredNoteLinkCount) & " ;"
    W "    dafm:registeredRelationshipCount " & CStr(registeredRelationshipGuids.Count) & " ;"
    W "    dafm:generalizationCount " & CStr(inheritanceCount) & " ;"
    W "    dafm:warningCount " & CStr(warningCount) & " ;"
    W "    dafm:legacyProfileConceptCount " & CStr(legacyProfileConceptCount) & " ;"
    W "    dafm:legacyProfileRelationshipCount " & CStr(legacyProfileRelationshipCount) & " ;"
    W "    dafm:quickLinkRuleCount " & CStr(quickLinkRuleCount) & " ."
    W ""
End Sub

' ---------------------------------------------------------------------------
' Run
' ---------------------------------------------------------------------------

Sub TestGenerateDAFSemanticModel()
    Dim outputFolder

    If Trim(CStr(metamodelPackageGUID)) = "" Then
        Session.Prompt "Please configure metamodelPackageGUID in DAF M3 Conf.", promptOK
        Exit Sub
    End If

    If Trim(CStr(ProfileName)) = "" Then
        Session.Prompt "Please configure ProfileName in DAF M3 Conf.", promptOK
        Exit Sub
    End If

    outputFolder = GetRDFOutputFolder()
    If Trim(CStr(outputFolder)) = "" Then Exit Sub

    GenerateDAFSemanticModel metamodelPackageGUID, outputFolder
End Sub

TestGenerateDAFSemanticModel
