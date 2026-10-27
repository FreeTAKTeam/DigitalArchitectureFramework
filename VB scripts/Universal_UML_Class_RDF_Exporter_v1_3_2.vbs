Option Explicit
!INC Local Scripts.EAConstants-VBScript

' =============================================================================
' Universal UML Class RDF Exporter for Sparx Enterprise Architect
'
' Version: 1.3.2
'
' PURPOSE
' -------
' Export UML Classes from the currently selected EA package tree to Turtle RDF.
'
' Refactoring goals in 1.1.0:
'   - centralize attribute serialization
'   - centralize multiplicity normalization
'   - centralize stereotype/meta-type serialization
'   - centralize tagged value export
'   - remove duplicate local/external attribute routines
'   - keep UML semantics separate from EA provenance
'
' Additions in 1.2.0:
'   - preserve EA UML AssociationClass <-> Association connector identity
'   - export association class attributes and the association-class link
'   - export UML Enumeration classifiers and their literal attributes
'   - resolve attribute classifier IRIs by unique name when EA ClassifierID is absent
'   - preserve local and first-level external classifier references
'
' Additions in 1.3.0:
'   - recover Association Classes via Subtype=17, MiscData(3), and Connector.AssociationClass
'   - index association-class links before serializing classifier records
'   - separate exporter version from UML model version (EA Package.Version)
'   - version-scoped RDF IRIs, OWL version metadata, versioned filenames
'   - require explicit confirmation before overwriting an existing export
'
' 1.3.1: Verify that each local Association Class refers to a serialized
'        Association; recover missing bidirectional RDF links and report
'        unresolved connector IDs and excluded connector endpoints.
' 1.3.2: Preserve valid EA Association Class connectors even when a connector
'        endpoint has an EA element type outside the UML Class filter. Such
'        endpoints remain typed uml:ExternalElement (not fabricated Classes).
'        Report endpoint types and fallback counts for audit.
'
' UML rule:
'   Blank attribute multiplicity is exported as 1..1.
'   Connector-end multiplicities are preserved exactly as modeled in EA.
'
' =============================================================================

Const EXPORTER_VERSION = "1.3.2"

Const adTypeText = 2
Const adSaveCreateOverWrite = 2

Dim outStream
Dim reportStream

Dim rootPackage
Dim rootGuid
Dim modelPrefixBase
Dim modelVersion
Dim canonicalModelIri
Dim versionModelIri

Dim outputFile
Dim reportFile

Dim packageIriById
Dim classIriById
Dim classIriByGuid
Dim classifierIriByName
Dim ambiguousClassifierNames
Dim associationClassIriByConnectorId
Dim associationClassConnectorIdByClassId
Dim associationClassClassIds
Dim associationClassLinkedConnectorIds
Dim associationClassLinkFailureCount
Dim associationClassUnresolvedCount
Dim exportedConnectorGuids
Dim externalClassIriById
Dim externalClassWrittenById
Dim otherAssociationEndpointIriById
Dim associationEndpointFallbackCount
Dim associationConnectorFallbackCount

Dim packageCount
Dim classCount
Dim attributeCount
Dim relationshipCount
Dim externalClassCount
Dim externalAttributeCount
Dim taggedValueCount
Dim associationClassCount
Dim enumerationCount
Dim enumerationLiteralCount
Dim associationClassLinkCount


' =============================================================================
' MAIN
' =============================================================================

Sub Main()

    InitState

    Session.Output "Universal UML Class RDF Exporter v" & EXPORTER_VERSION
    Session.Output ""

    Set rootPackage = Repository.GetTreeSelectedPackage()

    If rootPackage Is Nothing Then
        Session.Output "ERROR: Select a package in the Project Browser."
        Exit Sub
    End If

    rootGuid = NormalizeGuid(rootPackage.PackageGUID)
    canonicalModelIri = "urn:uml:model:" & rootGuid

    ' Package.Version is the version of the selected domain model,
    ' distinct from this exporter's software version.
    Dim suggestedVersion
    suggestedVersion = Trim(CStr(rootPackage.Version))
    If suggestedVersion = "" Then suggestedVersion = "0.1.0"
    modelVersion = Trim(InputBox( _
        "Version of UML model '" & rootPackage.Name & "' (separate from exporter version):", _
        "UML model version", suggestedVersion))
    If modelVersion = "" Then
        Session.Output "Export cancelled: a model version is required."
        Exit Sub
    End If
    If Not IsValidModelVersion(modelVersion) Then
        Session.Output "ERROR: Invalid model version. Use letters, digits, '.', '-', '_', '+'; start with a letter or digit."
        Exit Sub
    End If

    versionModelIri = canonicalModelIri & ":version:" & modelVersion
    modelPrefixBase = versionModelIri & "#"

    Dim defaultFile
    defaultFile = "C:\tmp\UML-" & SafeFileName(rootPackage.Name) & "-v" & SafeFileName(modelVersion) & ".ttl"

    outputFile = InputBox( _
        "Turtle output file for UML package '" & rootPackage.Name & "':", _
        "Universal UML RDF Export", _
        defaultFile)

    If Trim(CStr(outputFile)) = "" Then
        Session.Output "Export cancelled."
        Exit Sub
    End If

    EnsureParentFolder outputFile
    reportFile = ReplaceExtension(outputFile, ".report.txt")
    If Not ConfirmOverwrite(outputFile, reportFile) Then
        Session.Output "Export cancelled: existing version was preserved."
        Exit Sub
    End If

    ' Pass 1: index packages/classes and Association Class ownership BEFORE RDF.
    CollectPackage rootPackage
    DiscoverAssociationClasses rootPackage
    associationClassCount = CountLocalAssociationClasses()

    OpenStreams
    WriteHeader

    ' Pass 2: serialize packages/classes/connectors.
    WritePackageTree rootPackage, ""
    WritePackageClasses rootPackage
    EnsureAssociationClassLinks

    WriteAuditSummary
    CloseStreams

    Session.Output ""
    Session.Output "Export complete."
    Session.Output "Model version: " & modelVersion
    Session.Output "Versioned model IRI: " & versionModelIri
    Session.Output "RDF:    " & outputFile
    Session.Output "Report: " & reportFile
    Session.Output ""
    Session.Output _
        "Packages: " & packageCount & _
        "; Classifiers: " & classCount & _
        "; Attributes: " & attributeCount & _
        "; Relationships: " & relationshipCount & _
        "; Association-class links: " & associationClassLinkCount

End Sub


' =============================================================================
' INITIALIZATION
' =============================================================================

Sub InitState()

    Set packageIriById = NewDictionary()
    Set classIriById = NewDictionary()
    Set classIriByGuid = NewDictionary()
    Set classifierIriByName = NewDictionary()
    Set ambiguousClassifierNames = NewDictionary()
    Set associationClassIriByConnectorId = NewDictionary()
    Set associationClassConnectorIdByClassId = NewDictionary()
    Set associationClassClassIds = NewDictionary()
    Set associationClassLinkedConnectorIds = NewDictionary()
    Set exportedConnectorGuids = NewDictionary()
    Set externalClassIriById = NewDictionary()
    Set externalClassWrittenById = NewDictionary()
    Set otherAssociationEndpointIriById = NewDictionary()

    packageCount = 0
    classCount = 0
    attributeCount = 0
    relationshipCount = 0
    externalClassCount = 0
    externalAttributeCount = 0
    taggedValueCount = 0
    associationClassCount = 0
    enumerationCount = 0
    enumerationLiteralCount = 0
    associationClassLinkCount = 0
    associationClassUnresolvedCount = 0
    associationClassLinkFailureCount = 0
    associationEndpointFallbackCount = 0
    associationConnectorFallbackCount = 0

End Sub


Function NewDictionary()
    Dim d
    Set d = CreateObject("Scripting.Dictionary")
    d.CompareMode = 1
    Set NewDictionary = d
End Function


' =============================================================================
' STREAMS
' =============================================================================

Sub OpenStreams()

    Set outStream = CreateObject("ADODB.Stream")
    outStream.Type = adTypeText
    outStream.Charset = "utf-8"
    outStream.Open

    Set reportStream = CreateObject("ADODB.Stream")
    reportStream.Type = adTypeText
    reportStream.Charset = "utf-8"
    reportStream.Open

End Sub


Sub CloseStreams()

    outStream.SaveToFile outputFile, adSaveCreateOverWrite
    outStream.Close

    reportStream.SaveToFile reportFile, adSaveCreateOverWrite
    reportStream.Close

End Sub


Sub W(s)
    outStream.WriteText CStr(s) & vbCrLf
End Sub


Sub Report(s)
    reportStream.WriteText CStr(s) & vbCrLf
End Sub


' =============================================================================
' RDF HEADER
' =============================================================================

Sub WriteHeader()

    W "@prefix uml:     <urn:uml:vocabulary#> ."
    W "@prefix ea:      <urn:sparx:ea:vocabulary#> ."
    W "@prefix m:       <" & modelPrefixBase & "> ."
    W "@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ."
    W "@prefix owl:     <http://www.w3.org/2002/07/owl#> ."
    W "@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> ."
    W "@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> ."
    W "@prefix dcterms: <http://purl.org/dc/terms/> ."
    W ""

    W "uml:Model a rdfs:Class ."
    W "uml:Package a rdfs:Class ."
    W "uml:Class a rdfs:Class ."
    W "uml:AssociationClass a rdfs:Class ; rdfs:subClassOf uml:Class ."
    W "uml:Enumeration a rdfs:Class ; rdfs:subClassOf uml:Class ."
    W "uml:EnumerationLiteral a rdfs:Class ."
    W "uml:ExternalClass a rdfs:Class ; rdfs:subClassOf uml:Class ."
    W "uml:ExternalElement a rdfs:Class ."
    W "uml:Attribute a rdfs:Class ."
    W "uml:Relationship a rdfs:Class ."
    W "uml:TaggedValue a rdfs:Class ."
    W ""

    W "uml:rootPackage a rdf:Property ."
    W "uml:parentPackage a rdf:Property ."
    W "uml:containedInPackage a rdf:Property ."
    W "uml:hasAttribute a rdf:Property ."
    W "uml:hasLiteral a rdf:Property ."
    W "uml:literalValue a rdf:Property ."
    W "uml:associationClass a rdf:Property ."
    W "uml:associationClassOf a rdf:Property ."
    W "uml:hasTaggedValue a rdf:Property ."
    W "uml:source a rdf:Property ."
    W "uml:target a rdf:Property ."
    W "uml:typeName a rdf:Property ."
    W "uml:typeGuid a rdf:Property ."
    W "uml:lower a rdf:Property ."
    W "uml:upper a rdf:Property ."
    W "uml:sourceRole a rdf:Property ."
    W "uml:targetRole a rdf:Property ."
    W "uml:sourceMultiplicity a rdf:Property ."
    W "uml:targetMultiplicity a rdf:Property ."
    W "uml:sourceNavigability a rdf:Property ."
    W "uml:targetNavigability a rdf:Property ."
    W "uml:sourceAggregation a rdf:Property ."
    W "uml:targetAggregation a rdf:Property ."
    W "uml:relationshipType a rdf:Property ."
    W ""

    W "ea:guid a rdf:Property ."
    W "ea:elementId a rdf:Property ."
    W "ea:packageId a rdf:Property ."
    W "ea:connectorId a rdf:Property ."
    W "ea:stereotype a rdf:Property ."
    W "ea:stereotypeEx a rdf:Property ."
    W "ea:fqStereotype a rdf:Property ."
    W "ea:metaType a rdf:Property ."
    W "ea:elementType a rdf:Property ."
    W "ea:direction a rdf:Property ."
    W "ea:visibility a rdf:Property ."
    W "ea:tagName a rdf:Property ."
    W "ea:tagValue a rdf:Property ."
    W ""

    ' Unversioned model identity declares the version-specific ontology.
    W "<" & canonicalModelIri & "> a owl:Ontology ;"
    W "    owl:versionIRI m:model ."
    W ""

    W "m:model"
    W "    a owl:Ontology, uml:Model ;"
    W "    dcterms:title " & Lit(rootPackage.Name) & " ;"
    W "    owl:versionInfo " & Lit(modelVersion) & " ;"
    W "    dcterms:isVersionOf <" & canonicalModelIri & "> ;"
    W "    dcterms:created " & TypedLit(IsoDateTime(Now), "dateTime") & " ;"
    W "    ea:guid " & Lit(rootPackage.PackageGUID) & " ;"
    W "    uml:rootPackage " & ResourceIri("package", rootPackage.PackageGUID) & " ."
    W ""

    Report "UNIVERSAL UML CLASS RDF EXPORT REPORT"
    Report "Generated: " & Now
    Report "Exporter version: " & EXPORTER_VERSION
    Report "Model version: " & modelVersion
    Report "Canonical model IRI: " & canonicalModelIri
    Report "Version-specific ontology: " & versionModelIri & "#model"
    Report "Root package: " & rootPackage.Name
    Report "Root GUID: " & rootPackage.PackageGUID
    Report ""

End Sub


' =============================================================================
' COLLECTION / INDEXING
' =============================================================================

Sub CollectPackage(pkg)

    Dim pIri
    pIri = ResourceIri("package", pkg.PackageGUID)

    If Not packageIriById.Exists(CStr(pkg.PackageID)) Then
        packageIriById.Add CStr(pkg.PackageID), pIri
        packageCount = packageCount + 1
    End If

    Dim el
    For Each el In pkg.Elements
        If IsExportableClassifier(el) Then CollectClass el
    Next

    Dim childPkg
    For Each childPkg In pkg.Packages
        CollectPackage childPkg
    Next

End Sub


Sub CollectClass(el)

    Dim iri
    Dim guid

    iri = ResourceIri("class", el.ElementGUID)
    guid = NormalizeGuid(el.ElementGUID)

    If Not classIriById.Exists(CStr(el.ElementID)) Then
        classIriById.Add CStr(el.ElementID), iri
        classIriByGuid.Add guid, iri
        classCount = classCount + 1

        If IsUMLEnumeration(el) Then enumerationCount = enumerationCount + 1

        ' Name lookup is only a fallback for attributes lacking ClassifierID.
        ' Ambiguous names must never be resolved to an arbitrary classifier.
        Dim nameKey
        nameKey = LCase(Trim(CStr(el.Name)))
        If nameKey <> "" Then
            If classifierIriByName.Exists(nameKey) Then
                classifierIriByName.Remove nameKey
                ambiguousClassifierNames.Add nameKey, True
            ElseIf Not ambiguousClassifierNames.Exists(nameKey) Then
                classifierIriByName.Add nameKey, iri
            End If
        End If

        ' Association Classes are discovered in a separate pass, after all
        ' classes are indexed (including via connector back-references).
    End If

End Sub


Function IsUMLClass(el)
    Dim kind
    kind = LCase(Trim(CStr(el.Type)))
    IsUMLClass = (kind = "class" Or kind = "associationclass")
End Function


Function IsUMLEnumeration(el)
    Dim kind
    Dim stereo
    kind = LCase(Trim(CStr(el.Type)))
    stereo = LCase(Trim(CStr(el.Stereotype)))
    IsUMLEnumeration = (kind = "enumeration" Or stereo = "enumeration")
End Function


Function IsExportableClassifier(el)
    IsExportableClassifier = IsUMLClass(el) Or IsUMLEnumeration(el)
End Function


Function SafeAssociationSubtype(el)
    SafeAssociationSubtype = False
    If Not IsUMLClass(el) Then Exit Function
    On Error Resume Next
    Dim n
    n = CLng(el.Subtype)
    If Err.Number = 0 Then SafeAssociationSubtype = (n = 17)
    Err.Clear
    On Error GoTo 0
End Function


Function AssociationClassConnectorId(el)
    AssociationClassConnectorId = 0
    If Not IsUMLClass(el) Then Exit Function

    Dim k
    k = CStr(el.ElementID)
    If associationClassConnectorIdByClassId.Exists(k) Then
        AssociationClassConnectorId = CLng(associationClassConnectorIdByClassId(k))
        Exit Function
    End If

    ' EA APIs differ across versions. The subtype is authoritative for the
    ' class kind; the association connector ID can be obtained by either API.
    On Error Resume Next
    Dim identifier
    identifier = CLng(el.AssociationClassConnectorID)
    If Err.Number <> 0 Then
        identifier = 0
        Err.Clear
    End If
    If identifier <= 0 And SafeAssociationSubtype(el) Then
        identifier = CLng(el.MiscData(3))
        If Err.Number <> 0 Then
            identifier = 0
            Err.Clear
        End If
    End If
    On Error GoTo 0

    If identifier > 0 Then AssociationClassConnectorId = identifier
End Function


Function IsUMLAssociationClass(el)
    IsUMLAssociationClass = False
    If Not IsUMLClass(el) Then Exit Function
    IsUMLAssociationClass = SafeAssociationSubtype(el) Or _
                            associationClassClassIds.Exists(CStr(el.ElementID)) Or _
                            (AssociationClassConnectorId(el) > 0)
End Function


Sub RegisterAssociationClass(el, connectorId)
    If el Is Nothing Then Exit Sub
    If Not IsUMLClass(el) Then Exit Sub

    Dim classKey
    classKey = CStr(el.ElementID)
    If Not associationClassClassIds.Exists(classKey) Then
        associationClassClassIds.Add classKey, True
    End If

    If connectorId <= 0 Then Exit Sub
    Dim connectorKey
    connectorKey = CStr(connectorId)
    associationClassConnectorIdByClassId(classKey) = CLng(connectorId)
    ' The class is serialized as a local class if in the selected package,
    ' or resolved lazily as an external class if necessary.
    If classIriById.Exists(classKey) Then
        associationClassIriByConnectorId(connectorKey) = classIriById(classKey)
    End If
End Sub


Sub DiscoverAssociationClasses(pkg)
    ' Pass A: discover Class.Subtype=17 and class->association ID.
    Dim el
    For Each el In pkg.Elements
        If IsUMLClass(el) Then
            Dim connectorId
            connectorId = AssociationClassConnectorId(el)
            If SafeAssociationSubtype(el) Or connectorId > 0 Then
                RegisterAssociationClass el, connectorId
            End If
        End If
    Next

    ' Pass B: use Connector.AssociationClass (reverse lookup). This also
    ' recovers cases where AssociationClassConnectorID is 0 in the EA API.
    Dim c
    For Each el In pkg.Elements
        If IsExportableClassifier(el) Then
            For Each c In el.Connectors
                If LCase(Trim(CStr(c.Type))) = "association" Then
                    On Error Resume Next
                    Dim assocEl
                    Set assocEl = Nothing
                    Set assocEl = c.AssociationClass
                    If Err.Number <> 0 Then
                        Set assocEl = Nothing
                        Err.Clear
                    End If
                    On Error GoTo 0
                    If Not assocEl Is Nothing Then
                        RegisterAssociationClass assocEl, CLng(c.ConnectorID)
                    End If
                End If
            Next
        End If
    Next

    Dim childPkg
    For Each childPkg In pkg.Packages
        DiscoverAssociationClasses childPkg
    Next
End Sub


Function CountLocalAssociationClasses()
    Dim k
    CountLocalAssociationClasses = 0
    associationClassUnresolvedCount = 0
    For Each k In associationClassClassIds.Keys
        If classIriById.Exists(k) Then
            CountLocalAssociationClasses = CountLocalAssociationClasses + 1
            If Not associationClassConnectorIdByClassId.Exists(k) Then
                associationClassUnresolvedCount = associationClassUnresolvedCount + 1
            End If
        End If
    Next
End Function


Function AssociationClassConnectorIri(el)
    AssociationClassConnectorIri = ""

    Dim linkedId
    linkedId = AssociationClassConnectorId(el)
    If linkedId <= 0 Then Exit Function

    On Error Resume Next
    Dim c
    Set c = Repository.GetConnectorByID(linkedId)
    If Err.Number = 0 And Not c Is Nothing Then
        AssociationClassConnectorIri = ResourceIri("relationship", c.ConnectorGUID)
    End If
    Err.Clear
    On Error GoTo 0
End Function


' =============================================================================
' PACKAGE EXPORT
' =============================================================================

Sub WritePackageTree(pkg, parentIri)

    Dim pIri
    pIri = PackageIri(pkg.PackageID)

    W "# Package: " & OneLine(pkg.Name)
    W pIri
    W "    a uml:Package ;"
    W "    rdfs:label " & Lit(pkg.Name) & " ;"
    W "    ea:guid " & Lit(pkg.PackageGUID) & " ;"
    W "    ea:packageId " & TypedLit(pkg.PackageID, "integer") & " ;"

    WriteOptionalLiteral "dcterms:description", pkg.Notes

    If parentIri <> "" Then
        W "    uml:parentPackage " & parentIri & " ."
    Else
        W "    rdf:type uml:Package ."
    End If

    W ""

    Dim childPkg
    For Each childPkg In pkg.Packages
        WritePackageTree childPkg, pIri
    Next

End Sub


' =============================================================================
' CLASS EXPORT
' =============================================================================

Sub WritePackageClasses(pkg)

    Dim el

    For Each el In pkg.Elements
        If IsExportableClassifier(el) Then
            WriteClass el, PackageIri(pkg.PackageID)
        End If
    Next

    Dim childPkg
    For Each childPkg In pkg.Packages
        WritePackageClasses childPkg
    Next

    For Each el In pkg.Elements
        If IsExportableClassifier(el) Then
            WriteClassConnectors el
        End If
    Next

End Sub


Sub WriteClass(el, packageIri)

    Dim iri
    iri = ClassIri(el.ElementID)

    Dim classifierKind
    classifierKind = "uml:Class"
    If IsUMLEnumeration(el) Then
        classifierKind = "uml:Enumeration"
    ElseIf IsUMLAssociationClass(el) Then
        classifierKind = "uml:AssociationClass"
    End If

    W "# Classifier: " & OneLine(el.Name)
    W iri
    W "    a " & classifierKind & " ;"
    W "    rdfs:label " & Lit(el.Name) & " ;"
    W "    ea:guid " & Lit(el.ElementGUID) & " ;"
    W "    ea:elementId " & TypedLit(el.ElementID, "integer") & " ;"
    W "    ea:elementType " & Lit(el.Type) & " ;"
    W "    uml:containedInPackage " & packageIri & " ;"

    WriteElementCommonMetadata el

    Dim linkedRelationship
    linkedRelationship = AssociationClassConnectorIri(el)
    If linkedRelationship <> "" Then
        W "    uml:associationClassOf " & linkedRelationship & " ;"
    End If

    W "    ea:packageId " & TypedLit(el.PackageID, "integer") & " ."
    W ""

    WriteAttributes el, iri, False
    ExportElementTaggedValues el, iri

End Sub


Sub WriteElementCommonMetadata(el)

    WriteOptionalLiteral "dcterms:description", el.Notes
    WriteOptionalLiteral "dcterms:alternative", el.Alias
    WriteOptionalLiteral "ea:stereotype", el.Stereotype
    WriteOptionalLiteral "ea:stereotypeEx", el.StereotypeEx
    WriteOptionalLiteral "ea:fqStereotype", SafeElementFQStereotype(el)
    WriteOptionalLiteral "ea:metaType", SafeElementMetaType(el)
    WriteOptionalLiteral "dcterms:type", el.Status
    WriteOptionalLiteral "dcterms:hasVersion", el.Version
    WriteOptionalLiteral "dcterms:creator", el.Author

    If IsDate(el.Created) Then
        W "    dcterms:created " & TypedLit(IsoDateTime(el.Created), "dateTime") & " ;"
    End If

    If IsDate(el.Modified) Then
        W "    dcterms:modified " & TypedLit(IsoDateTime(el.Modified), "dateTime") & " ;"
    End If

End Sub


Sub WriteOptionalLiteral(predicate, value)

    If Trim(CStr(value)) <> "" Then
        W "    " & predicate & " " & Lit(value) & " ;"
    End If

End Sub


' =============================================================================
' ATTRIBUTE EXPORT
' =============================================================================

Sub WriteAttributes(el, ownerIri, isExternal)

    Dim a
    Dim index

    index = 0

    For Each a In el.Attributes

        index = index + 1

        If isExternal Then
            externalAttributeCount = externalAttributeCount + 1
        Else
            attributeCount = attributeCount + 1
        End If

        If IsUMLEnumeration(el) Then
            enumerationLiteralCount = enumerationLiteralCount + 1
            WriteEnumerationLiteral el, a, ownerIri, index, isExternal
        Else
            WriteAttribute el, a, ownerIri, index, isExternal
        End If

    Next

End Sub


Sub WriteAttribute(el, a, ownerIri, index, isExternal)

    Dim iriKind
    If isExternal Then
        iriKind = "external_attribute"
    Else
        iriKind = "attribute"
    End If

    Dim attrIri
    attrIri = ResourceIriWithSuffix(iriKind, el.ElementGUID, CStr(index))

    W ownerIri & " uml:hasAttribute " & attrIri & " ."
    W attrIri
    W "    a uml:Attribute ;"
    W "    rdfs:label " & Lit(a.Name) & " ;"
    W "    uml:typeName " & Lit(a.Type) & " ;"
    W "    uml:lower " & Lit(AttributeLowerBound(a)) & " ;"
    W "    uml:upper " & Lit(AttributeUpperBound(a)) & " ;"

    WriteOptionalLiteral "rdf:value", a.Default
    WriteOptionalLiteral "ea:visibility", a.Visibility
    WriteOptionalLiteral "ea:stereotype", a.Stereotype
    WriteOptionalLiteral "dcterms:description", a.Notes

    Dim classifierIri
    classifierIri = AttributeClassifierIri(a)

    If classifierIri <> "" Then
        W "    uml:typeGuid " & classifierIri & " ;"
    End If

    W "    ea:elementId " & TypedLit(el.ElementID, "integer") & " ."
    W ""

    ExportAttributeTaggedValues a, attrIri

End Sub


Sub WriteEnumerationLiteral(el, a, ownerIri, index, isExternal)

    Dim iriKind
    iriKind = "attribute"
    If isExternal Then iriKind = "external_attribute"

    Dim literalIri
    literalIri = ResourceIriWithSuffix(iriKind, el.ElementGUID, CStr(index))

    W ownerIri & " uml:hasLiteral " & literalIri & " ."
    W literalIri
    W "    a uml:EnumerationLiteral ;"
    W "    rdfs:label " & Lit(a.Name) & " ;"
    W "    uml:literalValue " & Lit(a.Name) & " ;"

    WriteOptionalLiteral "rdf:value", a.Default
    WriteOptionalLiteral "ea:visibility", a.Visibility
    WriteOptionalLiteral "ea:stereotype", a.Stereotype
    WriteOptionalLiteral "dcterms:description", a.Notes

    W "    ea:elementId " & TypedLit(el.ElementID, "integer") & " ."
    W ""

    ExportAttributeTaggedValues a, literalIri

End Sub


Function AttributeLowerBound(a)

    Dim v
    v = Trim(CStr(a.LowerBound))

    If v = "" Then
        AttributeLowerBound = "1"
    Else
        AttributeLowerBound = v
    End If

End Function


Function AttributeUpperBound(a)

    Dim v
    v = Trim(CStr(a.UpperBound))

    If v = "" Then
        AttributeUpperBound = "1"
    Else
        AttributeUpperBound = v
    End If

End Function


Function AttributeClassifierIri(a)

    AttributeClassifierIri = ""

    On Error Resume Next
    Dim classifierId
    classifierId = CLng(a.ClassifierID)
    If Err.Number <> 0 Then
        classifierId = 0
        Err.Clear
    End If
    On Error GoTo 0

    If classifierId > 0 Then
        AttributeClassifierIri = GetClassEndpointIri(classifierId)
        If AttributeClassifierIri <> "" Then Exit Function
    End If

    ' EA sometimes stores the type name but no classifier ID.
    ' Resolve only unique local classifiers, avoiding ambiguous guesses.
    Dim nameKey
    nameKey = LCase(Trim(CStr(a.Type)))
    If classifierIriByName.Exists(nameKey) Then
        AttributeClassifierIri = classifierIriByName(nameKey)
    End If

End Function


' =============================================================================
' CONNECTOR EXPORT
' =============================================================================

Sub WriteClassConnectors(el)

    Dim c

    For Each c In el.Connectors
        If IsClassConnector(c) Then WriteConnector c
    Next

    ' The class part of an AssociationClass may be inside the selected
    ' package while its association connector is not reachable from
    ' any selected endpoint. Preserve that cross-boundary relationship.
    Dim linkedId
    linkedId = AssociationClassConnectorId(el)
    If linkedId > 0 Then
        On Error Resume Next
        Dim linkedConnector
        Set linkedConnector = Repository.GetConnectorByID(linkedId)
        If Err.Number <> 0 Then
            Err.Clear
            Set linkedConnector = Nothing
        End If
        On Error GoTo 0
        If Not linkedConnector Is Nothing Then
            If IsClassConnector(linkedConnector) Then WriteConnector linkedConnector
        End If
    End If

End Sub


Function IsClassConnector(c)

    IsClassConnector = False

    On Error Resume Next

    Dim sourceEl
    Dim targetEl

    Set sourceEl = Repository.GetElementByID(c.ClientID)
    Set targetEl = Repository.GetElementByID(c.SupplierID)

    If Err.Number <> 0 Then
        Err.Clear
        On Error GoTo 0
        Exit Function
    End If

    If sourceEl Is Nothing Or targetEl Is Nothing Then
        On Error GoTo 0
        Exit Function
    End If

    IsClassConnector = IsExportableClassifier(sourceEl) And IsExportableClassifier(targetEl)

    On Error GoTo 0

End Function


Sub WriteConnector(c)
    ' Existing general-path behavior: only UML classifier endpoints.
    WriteConnectorWithMode c, False
End Sub


Sub WriteConnectorWithMode(c, preserveEAEndpoints)

    Dim guid
    guid = NormalizeGuid(c.ConnectorGUID)

    If exportedConnectorGuids.Exists(guid) Then Exit Sub

    Dim sourceIri
    Dim targetIri

    If preserveEAEndpoints Then
        ' Only used for a positively linked EA Association Class connector.
        ' Do not silently drop an association just because EA exposes an
        ' endpoint as an ordinary Element instead of a UML Class.
        sourceIri = GetAssociationEndpointIri(c.ClientID)
        targetIri = GetAssociationEndpointIri(c.SupplierID)
    Else
        sourceIri = GetClassEndpointIri(c.ClientID)
        targetIri = GetClassEndpointIri(c.SupplierID)
    End If

    If sourceIri = "" Or targetIri = "" Then Exit Sub

    ' Resolve the association-class reference before writing the RDF
    ' relationship block: external-class resolution may serialize RDF.
    Dim associationClassIri
    associationClassIri = GetAssociationClassIri(c)

    exportedConnectorGuids.Add guid, True

    Dim relIri
    relIri = ResourceIri("relationship", c.ConnectorGUID)

    relationshipCount = relationshipCount + 1

    W "# Relationship: " & OneLine(c.Name)
    W relIri
    W "    a uml:Relationship ;"
    W "    uml:relationshipType " & Lit(c.Type) & " ;"
    W "    uml:source " & sourceIri & " ;"
    W "    uml:target " & targetIri & " ;"
    If associationClassIri <> "" Then
        W "    uml:associationClass " & associationClassIri & " ;"
        associationClassLinkCount = associationClassLinkCount + 1
        associationClassLinkedConnectorIds(CStr(c.ConnectorID)) = True
    End If
    W "    ea:guid " & Lit(c.ConnectorGUID) & " ;"
    W "    ea:connectorId " & TypedLit(c.ConnectorID, "integer") & " ;"

    WriteOptionalLiteral "rdfs:label", c.Name
    WriteOptionalLiteral "ea:direction", c.Direction
    WriteOptionalLiteral "ea:stereotype", c.Stereotype
    WriteOptionalLiteral "ea:stereotypeEx", c.StereotypeEx
    WriteOptionalLiteral "ea:fqStereotype", SafeConnectorFQStereotype(c)

    WriteConnectorEnd "source", c.ClientEnd
    WriteConnectorEnd "target", c.SupplierEnd

    W "    uml:targetAggregation " & Lit(AggregationName(c.SupplierEnd.Aggregation)) & " ."
    W ""

    ExportConnectorTaggedValues c, relIri

End Sub


Sub WriteConnectorEnd(prefix, connectorEnd)

    Dim rolePredicate
    Dim multiplicityPredicate
    Dim navigabilityPredicate
    Dim aggregationPredicate

    If LCase(prefix) = "source" Then
        rolePredicate = "uml:sourceRole"
        multiplicityPredicate = "uml:sourceMultiplicity"
        navigabilityPredicate = "uml:sourceNavigability"
        aggregationPredicate = "uml:sourceAggregation"
    Else
        rolePredicate = "uml:targetRole"
        multiplicityPredicate = "uml:targetMultiplicity"
        navigabilityPredicate = "uml:targetNavigability"
        aggregationPredicate = "uml:targetAggregation"
    End If

    WriteOptionalLiteral rolePredicate, connectorEnd.Role
    WriteOptionalLiteral multiplicityPredicate, connectorEnd.Cardinality
    WriteOptionalLiteral navigabilityPredicate, connectorEnd.Navigable

    ' Target aggregation is written by WriteConnector as the final predicate,
    ' therefore only source aggregation is emitted here.
    If LCase(prefix) = "source" Then
        W "    " & aggregationPredicate & " " & Lit(AggregationName(connectorEnd.Aggregation)) & " ;"
    End If

End Sub


Function AggregationName(value)

    Select Case CInt(value)
        Case 1
            AggregationName = "shared"
        Case 2
            AggregationName = "composite"
        Case Else
            AggregationName = "none"
    End Select

End Function


' =============================================================================
' ASSOCIATION CLASS RESOLUTION
' =============================================================================

Function GetAssociationClassIri(c)

    GetAssociationClassIri = ""

    ' Local class-first lookup remains reliable even if the API's optional
    ' Connector.AssociationClass object is unavailable in an older EA version.
    Dim connectorKey
    connectorKey = CStr(c.ConnectorID)
    If associationClassIriByConnectorId.Exists(connectorKey) Then
        GetAssociationClassIri = associationClassIriByConnectorId(connectorKey)
        Exit Function
    End If

    On Error Resume Next
    Dim associationEl
    Set associationEl = c.AssociationClass
    If Err.Number <> 0 Then
        Set associationEl = Nothing
        Err.Clear
    End If
    On Error GoTo 0

    If associationEl Is Nothing Then Exit Function
    If Not IsUMLClass(associationEl) Then Exit Function

    RegisterAssociationClass associationEl, CLng(c.ConnectorID)
    GetAssociationClassIri = GetClassEndpointIri(associationEl.ElementID)

End Function


Sub EnsureAssociationClassLinks()
    ' The EA Association Class may be correctly identified by Subtype=17 and
    ' AssociationClassConnectorID while its connector is not encountered during
    ' ordinary class connector traversal. Validate and export each such link.
    ' A positive ConnectorID alone is NOT evidence that the link was exported.
    Dim classKey
    Dim connectorId
    Dim connectorKey
    Dim classIri
    Dim relationIri
    Dim relationGuid
    Dim linkedConnector
    Dim details

    For Each classKey In associationClassClassIds.Keys
        If classIriById.Exists(CStr(classKey)) Then
            classIri = classIriById(CStr(classKey))
            If associationClassConnectorIdByClassId.Exists(CStr(classKey)) Then
                connectorId = CLng(associationClassConnectorIdByClassId(CStr(classKey)))
                connectorKey = CStr(connectorId)
                Set linkedConnector = Nothing

                On Error Resume Next
                Set linkedConnector = Repository.GetConnectorByID(connectorId)
                If Err.Number <> 0 Then
                    Set linkedConnector = Nothing
                    Err.Clear
                End If
                On Error GoTo 0

                If linkedConnector Is Nothing Then
                    associationClassLinkFailureCount = associationClassLinkFailureCount + 1
                    Report "WARNING: Association Class [ElementID=" & CStr(classKey) & _
                        "] refers to missing ConnectorID=" & connectorKey
                Else
                    relationGuid = NormalizeGuid(linkedConnector.ConnectorGUID)
                    relationIri = ResourceIri("relationship", linkedConnector.ConnectorGUID)
                    details = " [ConnectorID=" & connectorKey & ", Type=" & _
                        CStr(linkedConnector.Type) & ", ClientID=" & _
                        CStr(linkedConnector.ClientID) & ", SupplierID=" & _
                        CStr(linkedConnector.SupplierID) & "]"

                    If Not exportedConnectorGuids.Exists(relationGuid) Then
                        ' Ordinary UML-classifier associations are unchanged.
                        If IsClassConnector(linkedConnector) Then
                            WriteConnector linkedConnector
                        End If

                        If Not exportedConnectorGuids.Exists(relationGuid) Then
                            ' AssociationClassConnectorID is a positive EA link.
                            ' Keep this association even when its endpoints are
                            ' non-class EA elements, preserving their true types.
                            Report "RECOVERY ATTEMPT: Association Class [ElementID=" & _
                                CStr(classKey) & "]" & details
                            Report "  Client: " & AssociationEndpointDiagnostic(linkedConnector.ClientID)
                            Report "  Supplier: " & AssociationEndpointDiagnostic(linkedConnector.SupplierID)
                            WriteConnectorWithMode linkedConnector, True
                            If exportedConnectorGuids.Exists(relationGuid) Then
                                associationConnectorFallbackCount = associationConnectorFallbackCount + 1
                            End If
                        End If
                    End If

                    If exportedConnectorGuids.Exists(relationGuid) Then
                        If Not associationClassLinkedConnectorIds.Exists(connectorKey) Then
                            ' Preserve the semantic association-class link even
                            ' if Connector.AssociationClass is missing/NULL.
                            ' A class-side triple may already exist: a duplicate
                            ' RDF triple is harmless and ensures symmetry.
                            W relationIri & " uml:associationClass " & classIri & " ."
                            W classIri & " uml:associationClassOf " & relationIri & " ."
                            W ""
                            associationClassLinkedConnectorIds(connectorKey) = True
                            associationClassLinkCount = associationClassLinkCount + 1
                            Report "RECOVERED: Association Class [ElementID=" & _
                                CStr(classKey) & "] link to exported relationship" & details
                        End If
                    Else
                        associationClassLinkFailureCount = associationClassLinkFailureCount + 1
                        Report "WARNING: Association Class [ElementID=" & _
                            CStr(classKey) & "] connector NOT exported" & details
                        Report "  Client: " & AssociationEndpointDiagnostic(linkedConnector.ClientID)
                        Report "  Supplier: " & AssociationEndpointDiagnostic(linkedConnector.SupplierID)
                        Report "  One or both EA endpoints could not be retrieved; no RDF relation was fabricated."
                    End If
                End If
            Else
                associationClassLinkFailureCount = associationClassLinkFailureCount + 1
                Report "WARNING: Association Class [ElementID=" & CStr(classKey) & _
                    "] has no resolvable association connector ID."
            End If
        End If
    Next
End Sub


' =============================================================================
' ASSOCIATION CLASS ENDPOINT PRESERVATION
' =============================================================================

Function AssociationEndpointDiagnostic(elementId)
    Dim el
    Set el = Nothing
    On Error Resume Next
    Set el = Repository.GetElementByID(CLng(elementId))
    If Err.Number <> 0 Then
        AssociationEndpointDiagnostic = "ElementID=" & CStr(elementId) & _
            " API error=" & CStr(Err.Number) & ": " & Err.Description
        Err.Clear
        On Error GoTo 0
        Exit Function
    End If
    On Error GoTo 0
    If el Is Nothing Then
        AssociationEndpointDiagnostic = "ElementID=" & CStr(elementId) & " unavailable"
        Exit Function
    End If
    AssociationEndpointDiagnostic = "ElementID=" & CStr(elementId) & _
        ", Name=" & CStr(el.Name) & _
        ", Type=" & CStr(el.Type) & _
        ", MetaType=" & SafeElementMetaType(el) & _
        ", IsClassifier=" & CStr(IsExportableClassifier(el))
End Function


Function GetAssociationEndpointIri(elementId)
    ' A genuine EA Association Class refers to an existing EA Association.
    ' Retain its endpoints even when a profile exposes non-Class EA objects.
    ' Preserve their EA identities, but never type such endpoints as UML Classes.
    GetAssociationEndpointIri = GetClassEndpointIri(elementId)
    If GetAssociationEndpointIri <> "" Then Exit Function

    Dim elementKey
    elementKey = CStr(elementId)
    If otherAssociationEndpointIriById.Exists(elementKey) Then
        GetAssociationEndpointIri = otherAssociationEndpointIriById(elementKey)
        Exit Function
    End If

    Dim el
    Set el = Nothing
    On Error Resume Next
    Set el = Repository.GetElementByID(CLng(elementId))
    If Err.Number <> 0 Then
        Err.Clear
        Set el = Nothing
    End If
    On Error GoTo 0
    If el Is Nothing Then
        GetAssociationEndpointIri = ""
        Exit Function
    End If

    Dim iri
    iri = ResourceIri("external_element", el.ElementGUID)
    otherAssociationEndpointIriById.Add elementKey, iri
    associationEndpointFallbackCount = associationEndpointFallbackCount + 1

    W "# EA non-class endpoint of an Association Class: " & OneLine(el.Name)
    W iri
    W "    a uml:ExternalElement ;"
    W "    rdfs:label " & Lit(el.Name) & " ;"
    W "    ea:guid " & Lit(el.ElementGUID) & " ;"
    W "    ea:elementId " & TypedLit(el.ElementID, "integer") & " ;"
    W "    ea:elementType " & Lit(el.Type) & " ;"
    W "    ea:metaType " & Lit(SafeElementMetaType(el)) & " ;"
    W "    ea:packageId " & TypedLit(el.PackageID, "integer") & " ."
    W ""

    Report "RECOVERED EA ENDPOINT: " & AssociationEndpointDiagnostic(elementId) & _
        " (serialized as uml:ExternalElement, not uml:Class)"
    GetAssociationEndpointIri = iri
End Function


' =============================================================================
' EXTERNAL CLASSES
' =============================================================================

Function GetClassEndpointIri(elementId)

    If classIriById.Exists(CStr(elementId)) Then
        GetClassEndpointIri = classIriById(CStr(elementId))
        Exit Function
    End If

    If externalClassIriById.Exists(CStr(elementId)) Then
        GetClassEndpointIri = externalClassIriById(CStr(elementId))
        Exit Function
    End If

    On Error Resume Next

    Dim el
    Set el = Repository.GetElementByID(CLng(elementId))

    If Err.Number <> 0 Then
        Err.Clear
        Set el = Nothing
    End If

    On Error GoTo 0

    If el Is Nothing Then
        GetClassEndpointIri = ""
        Exit Function
    End If

    If Not IsExportableClassifier(el) Then
        GetClassEndpointIri = ""
        Exit Function
    End If

    Dim iri
    iri = ResourceIri("external_class", el.ElementGUID)

    externalClassIriById.Add CStr(elementId), iri
    externalClassCount = externalClassCount + 1

    WriteExternalClass el, iri

    GetClassEndpointIri = iri

End Function


Sub WriteExternalClass(el, iri)

    If externalClassWrittenById.Exists(CStr(el.ElementID)) Then Exit Sub
    externalClassWrittenById.Add CStr(el.ElementID), True

    Dim classifierKinds
    classifierKinds = "uml:ExternalClass"
    If IsUMLEnumeration(el) Then
        classifierKinds = classifierKinds & ", uml:Enumeration"
    ElseIf IsUMLAssociationClass(el) Then
        classifierKinds = classifierKinds & ", uml:AssociationClass"
    End If

    W "# External classifier: " & OneLine(el.Name)
    W iri
    W "    a " & classifierKinds & " ;"
    W "    rdfs:label " & Lit(el.Name) & " ;"
    W "    ea:guid " & Lit(el.ElementGUID) & " ;"
    W "    ea:elementId " & TypedLit(el.ElementID, "integer") & " ;"

    WriteElementCommonMetadata el

    Dim linkedRelationship
    linkedRelationship = AssociationClassConnectorIri(el)
    If linkedRelationship <> "" Then
        W "    uml:associationClassOf " & linkedRelationship & " ;"
    End If

    W "    ea:packageId " & TypedLit(el.PackageID, "integer") & " ."
    W ""

    WriteAttributes el, iri, True
    ExportElementTaggedValues el, iri

End Sub


' =============================================================================
' TAGGED VALUES
' =============================================================================

Sub ExportElementTaggedValues(el, ownerIri)
    ExportTaggedValueCollection el.TaggedValues, ownerIri, "tag", el.ElementGUID
End Sub


Sub ExportAttributeTaggedValues(a, ownerIri)

    On Error Resume Next

    ExportTaggedValueCollection a.TaggedValues, ownerIri, "attribute_tag", ownerIri

    Err.Clear
    On Error GoTo 0

End Sub


Sub ExportConnectorTaggedValues(c, ownerIri)
    ExportTaggedValueCollection c.TaggedValues, ownerIri, "relationship_tag", c.ConnectorGUID
End Sub


Sub ExportTaggedValueCollection(collection, ownerIri, iriKind, ownerKey)

    Dim tv
    Dim index

    index = 0

    For Each tv In collection

        index = index + 1
        taggedValueCount = taggedValueCount + 1

        Dim iri

        If Left(CStr(ownerKey), 2) = "m:" Then
            iri = CStr(ownerKey) & "_tag_" & CStr(index)
        Else
            iri = ResourceIriWithSuffix(iriKind, ownerKey, CStr(index))
        End If

        WriteTaggedValue ownerIri, iri, tv.Name, TaggedValueActualValue(tv)

    Next

End Sub


Sub WriteTaggedValue(ownerIri, tagIri, tagName, tagValue)

    W ownerIri & " uml:hasTaggedValue " & tagIri & " ."
    W tagIri
    W "    a uml:TaggedValue ;"
    W "    ea:tagName " & Lit(tagName) & " ;"
    W "    ea:tagValue " & Lit(tagValue) & " ."
    W ""

End Sub


Function TaggedValueActualValue(tv)

    Dim v
    v = CStr(tv.Value)

    If LCase(Trim(v)) = "<memo>" Then
        TaggedValueActualValue = CStr(tv.Notes)
    Else
        TaggedValueActualValue = v
    End If

End Function


' =============================================================================
' SAFE EA ACCESS
' =============================================================================

Function SafeElementFQStereotype(el)
    SafeElementFQStereotype = SafeEAString(el, "FQStereotype")
End Function


Function SafeElementMetaType(el)
    SafeElementMetaType = SafeEAString(el, "MetaType")
End Function


Function SafeConnectorFQStereotype(c)
    SafeConnectorFQStereotype = SafeEAString(c, "FQStereotype")
End Function


Function SafeEAString(obj, propertyName)

    SafeEAString = ""

    On Error Resume Next

    Dim value

    Select Case propertyName
        Case "FQStereotype"
            value = CStr(obj.FQStereotype)
        Case "MetaType"
            value = CStr(obj.MetaType)
        Case Else
            value = ""
    End Select

    If Err.Number = 0 Then SafeEAString = value

    Err.Clear
    On Error GoTo 0

End Function


' =============================================================================
' IDENTITIES / IRIs
' =============================================================================

Function PackageIri(packageId)

    If packageIriById.Exists(CStr(packageId)) Then
        PackageIri = packageIriById(CStr(packageId))
    Else
        PackageIri = "m:package_unknown_" & CStr(packageId)
    End If

End Function


Function ClassIri(elementId)

    If classIriById.Exists(CStr(elementId)) Then
        ClassIri = classIriById(CStr(elementId))
    Else
        ClassIri = "m:class_unknown_" & CStr(elementId)
    End If

End Function


Function ResourceIri(kind, guidValue)

    Dim g
    g = Replace(NormalizeGuid(guidValue), "-", "_")

    ResourceIri = "m:" & SafeLocal(kind) & "_" & g

End Function


Function ResourceIriWithSuffix(kind, guidValue, suffix)

    Dim g
    g = Replace(NormalizeGuid(guidValue), "-", "_")

    ResourceIriWithSuffix = _
        "m:" & SafeLocal(kind) & "_" & g & "_" & SafeLocal(suffix)

End Function


Function NormalizeGuid(guidValue)

    Dim s

    s = LCase(Trim(CStr(guidValue)))
    s = Replace(s, "{", "")
    s = Replace(s, "}", "")

    NormalizeGuid = s

End Function


' =============================================================================
' TURTLE HELPERS
' =============================================================================

Function Lit(value)
    Lit = """" & TurtleEscape(CStr(value)) & """"
End Function


Function TypedLit(value, xsdType)
    TypedLit = Lit(value) & "^^xsd:" & xsdType
End Function


Function TurtleEscape(value)

    Dim s
    s = CStr(value)

    s = Replace(s, "\", "\\")
    s = Replace(s, Chr(34), Chr(92) & Chr(34))
    s = Replace(s, vbCrLf, "\n")
    s = Replace(s, vbCr, "\n")
    s = Replace(s, vbLf, "\n")
    s = Replace(s, vbTab, "\t")

    TurtleEscape = s

End Function


Function SafeLocal(value)

    Dim s
    Dim i
    Dim ch
    Dim result

    s = CStr(value)
    result = ""

    For i = 1 To Len(s)

        ch = Mid(s, i, 1)

        If _
            (ch >= "A" And ch <= "Z") _
            Or (ch >= "a" And ch <= "z") _
            Or (ch >= "0" And ch <= "9") _
            Or ch = "_" _
            Or ch = "-" Then

            result = result & ch

        Else

            result = result & "_"

        End If

    Next

    If result = "" Then result = "unnamed"

    If Left(result, 1) >= "0" And Left(result, 1) <= "9" Then
        result = "n_" & result
    End If

    SafeLocal = result

End Function


' =============================================================================
' DATE HELPERS
' =============================================================================

Function IsoDateTime(d)

    IsoDateTime = _
        Year(d) & "-" & Pad2(Month(d)) & "-" & Pad2(Day(d)) & _
        "T" & Pad2(Hour(d)) & ":" & Pad2(Minute(d)) & ":" & Pad2(Second(d))

End Function


Function Pad2(n)

    If n < 10 Then
        Pad2 = "0" & CStr(n)
    Else
        Pad2 = CStr(n)
    End If

End Function


Function IsValidModelVersion(value)
    IsValidModelVersion = False
    If Trim(CStr(value)) = "" Then Exit Function
    Dim re
    Set re = CreateObject("VBScript.RegExp")
    re.Pattern = "^[A-Za-z0-9][A-Za-z0-9._+\-]*$"
    IsValidModelVersion = re.Test(CStr(value))
End Function


Function ConfirmOverwrite(ttlPath, auditPath)
    ConfirmOverwrite = True
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(ttlPath) Or fso.FileExists(auditPath) Then
        Dim reply
        reply = MsgBox("A Turtle export or audit report for this model version already exists." & vbCrLf & _
                       "Overwrite these files?" & vbCrLf & ttlPath, _
                       vbYesNo + vbExclamation + vbDefaultButton2, "Preserve model versions")
        If reply <> vbYes Then ConfirmOverwrite = False
    End If
End Function


' =============================================================================
' FILE HELPERS
' =============================================================================

Function SafeFileName(value)

    Dim s
    s = CStr(value)

    s = Replace(s, "\", "_")
    s = Replace(s, "/", "_")
    s = Replace(s, ":", "_")
    s = Replace(s, "*", "_")
    s = Replace(s, "?", "_")
    s = Replace(s, """", "_")
    s = Replace(s, "<", "_")
    s = Replace(s, ">", "_")
    s = Replace(s, "|", "_")

    SafeFileName = s

End Function


Function OneLine(value)

    Dim s
    s = CStr(value)

    s = Replace(s, vbCr, " ")
    s = Replace(s, vbLf, " ")

    OneLine = s

End Function


Sub EnsureParentFolder(filePath)

    Dim fso
    Dim folder

    Set fso = CreateObject("Scripting.FileSystemObject")
    folder = fso.GetParentFolderName(filePath)

    If folder <> "" And Not fso.FolderExists(folder) Then
        CreateFolderRecursive fso, folder
    End If

End Sub


Sub CreateFolderRecursive(fso, folderPath)

    If folderPath = "" Then Exit Sub
    If fso.FolderExists(folderPath) Then Exit Sub

    Dim parent
    parent = fso.GetParentFolderName(folderPath)

    If parent <> "" And Not fso.FolderExists(parent) Then
        CreateFolderRecursive fso, parent
    End If

    fso.CreateFolder folderPath

End Sub


Function ReplaceExtension(filePath, newExtension)

    Dim fso
    Dim folder
    Dim base

    Set fso = CreateObject("Scripting.FileSystemObject")

    folder = fso.GetParentFolderName(filePath)
    base = fso.GetBaseName(filePath)

    If folder = "" Then
        ReplaceExtension = base & newExtension
    Else
        ReplaceExtension = folder & "\" & base & newExtension
    End If

End Function


' =============================================================================
' REPORT
' =============================================================================

Sub WriteAuditSummary()

    Report "SUMMARY"
    Report "Packages exported: " & packageCount
    Report "Classifiers exported: " & classCount
    Report "Association classes exported: " & associationClassCount
    Report "Enumerations exported: " & enumerationCount
    Report "Enumeration literals exported: " & enumerationLiteralCount
    Report "Attributes (including enumeration literals) exported: " & attributeCount
    Report "Relationships exported: " & relationshipCount
    Report "Association-class links exported: " & associationClassLinkCount
    Report "Association-class links not exported: " & associationClassLinkFailureCount
    Report "Association-class connectors exported via fallback: " & associationConnectorFallbackCount
    Report "Non-class EA association endpoints preserved: " & associationEndpointFallbackCount
    Report "Local Association Classes without resolved association IDs: " & associationClassUnresolvedCount
    If associationClassCount = 0 Then
        Report "DIAGNOSTIC: No genuine EA Association Class found by Subtype=17, connector ID or reverse Connector.AssociationClass."
        Report "DIAGNOSTIC: Confirm the class was created/linked with EA's Association Class operation, not a manually drawn line."
    End If
    If associationClassCount > 0 And associationClassLinkCount = 0 Then
        Report "WARNING: Association Classes found but no links serialized; inspect connector diagnostics above."
    End If
    If associationClassUnresolvedCount > 0 Then
        Report "WARNING: Some Association Classes were identified by Subtype but their connector ID could not be resolved."
    End If
    Report "External referenced classes: " & externalClassCount
    Report "External class attributes exported: " & externalAttributeCount
    Report "Tagged values exported: " & taggedValueCount
    Report ""

    Report "MODEL VERSIONING"
    Report "Model version: " & modelVersion
    Report "Element IRIs are scoped to the model version; ea:guid retains cross-version provenance."
    Report "The canonical model IRI is stable across versions of this EA root package."
    Report "Existing export files are overwritten only with explicit confirmation."
    Report "Exporter software version is independent of the model version."
    Report ""

    Report "EXPORT POLICY"
    Report "UML Class, Association Class and Enumeration classifiers are exported."
    Report "Association Classes are detected by EA Subtype=17 and linked in both API directions."
    Report "A final consistency pass checks connector serialization and recovers valid missing RDF links."
    Report "Association Class attributes and links to Association connectors are preserved."
    Report "Enumeration attributes are exported as UML EnumerationLiterals."
    Report "Attribute classifiers are resolved by ID or unambiguous local name."
    Report "All child packages are recursively traversed."
    Report "Class-to-class and class-to-enumeration connectors are preserved."
    Report "Verified Association Class connectors can preserve non-class EA endpoints as uml:ExternalElement."
    Report "No stereotype-specific semantic interpretation is performed."
    Report "No relationship type inference is performed."
    Report "No property datatype normalization is performed."
    Report "Blank UML attribute multiplicity is normalized to 1..1."
    Report "Connector-end multiplicity is preserved exactly as modeled in EA."
    Report "Directly referenced external classes are imported at depth 1."
    Report "Connectors belonging exclusively to external classes are not traversed."
    Report ""

End Sub


Main
