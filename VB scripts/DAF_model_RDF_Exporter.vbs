Option Explicit
!INC Local Scripts.EAConstants-VBScript

' =============================================================================
' DAF 6.3 M1 RDF Model Exporter
'
' Exporter version:              0.5.0
' DAF framework version:         6.3
' Semantic metamodel export:     1.5.0
'
' PURPOSE
' -------
' Export a real DAF M1 model from Sparx Enterprise Architect to Turtle RDF for
' loading into the Rust/Oxigraph DAF runtime.
'
' The currently selected package in the EA Project Browser is the export root.
' The package tree is traversed recursively.
'
' IMPORTANT VERSION DISTINCTION
' -----------------------------
' DAF 6.3 is the modeling framework / language version.
' 1.5.0 is the version of the M3 -> RDF semantic metamodel exporter whose
' generated vocabulary is embedded here as the mapping contract.
'
' DESIGN
' ------
' - DAF element identity is derived from the stable EA GUID.
' - dafp:id is the canonical UUID; legacy ID/Id/id tagged values are suppressed.
' - EA GUIDs are also preserved explicitly as dafm:eaGuid.
' - Known DAF stereotype properties are mapped to predicates defined by the
'   semantic metamodel 1.5.0.
' - Confirmed legacy EuroCOM element stereotypes are normalized to current
'   DAF 6.3 concepts/properties before serialization.
' - Legacy qualitative application satisfaction values are normalized to the
'   current integer percentage scale in 25-point steps:
'       Highly Dissatisfied = 0
'       Not Satisfied = 25
'       Moderately Satisfied = 50
'       Satisfied = 75
'       Highly Satisfied = 100
' - Every tagged value is also preserved generically for traceability.
' - Relationships are first-class resources.
' - Relationship semantics are resolved first by exact current DAF stereotype,
'   then deterministically from current M2 endpoint classes where exactly one
'   DAF 6.3 RelationshipType is compatible.
' - Semantic relationship direction is governed by M2 source/target classes,
'   not blindly by EA ClientID/SupplierID.
' - Known DAF relationships emit forward and inverse graph projections.
' - Cross-boundary connectors are preserved.
' - Every directly referenced out-of-scope endpoint is fully imported as a
'   first-level external element (importDepth = 1). The exporter does NOT
'   traverse connectors of those external elements, preventing recursive graph
'   expansion beyond the immediate model boundary.
' - External elements and cross-boundary connectors are retained as lossless,
'   first-class federation resources.
' - EA FQStereotype is used where available to preserve the source MDG/profile
'   identity in Profile::Stereotype form; StereotypeEx is retained as provenance.
' - DAF interpretation remains source-preserving, but source metamodels that
'   are direct DAF ancestors/siblings are TRUSTED TRANSFORMATION SOURCES:
'       Chronos, TMF, BIZBOK and TOGAF.
'   Approved mappings from those profiles are applied immediately. The external
'   source resource remains dafi:ExternalElement and retains all provenance, but
'   is additionally typed with the corresponding DAF 6.3 concept.
' - Other source technologies remain non-destructive candidates only.
' - Cross-boundary connectors are explicitly typed dafi:ExternalRelationship.
'   Their original EA connector type/metatype/FQStereotype/profile is preserved.
' - Approved relationship transformations from trusted source metamodels emit
'   applied SemanticMappings and DAF predicate projections. If DAF 6.3 has no
'   semantically valid equivalent relationship, the source relationship remains
'   generic rather than being coerced to the only structurally possible type.
' - Structural endpoint-only relationship mappings remain candidates and use
'   confidence ""structural"", never ""deterministic"" semantic equivalence.
' - BPMN Activity/Event, XSD complex types and other semantically ambiguous
'   source objects are preserved without an applied DAF transformation.
' - Packages are exported using a small M1 instance vocabulary (dafi:).
' - Diagrams/views are deliberately deferred to the next iteration.
' - Unknown/legacy stereotypes and tags are preserved and reported, not dropped.
'
' This script does NOT require the M3 source package to exist in the model being
' exported. It is therefore suitable for existing DAF repositories such as
' EuroCOM that only have the DAF MDG/profile installed.
' =============================================================================


Const EXPORTER_VERSION = "0.5.0"
Const DAF_VERSION = "6.3"
Const METAMODEL_EXPORT_VERSION = "1.5.0"
Const PROFILE_NAME = "DAF"
Const adTypeText = 2
Const adSaveCreateOverWrite = 2

Dim outStream
Dim reportStream

Dim classMap
Dim propertyMap
Dim relationshipMap
Dim relationshipSourceMap
Dim relationshipTargetMap
Dim relationshipPairMap
Dim classParentMap

Dim legacyElementTypeMap
Dim legacyElementInjectedPropertyMap
Dim legacyPropertyAliasMap

Dim packageIriById
Dim elementIriById
Dim elementIriByGuid
Dim elementStereoById
Dim elementSourceStereoById
Dim exportedConnectorGuids

Dim externalEndpointIriById
Dim externalEndpointTypeById
Dim externalEndpointWrittenById
Dim externalMappedDAFTypeById
Dim externalMappedDAFStatusById
Dim externalSourceProfileById
Dim externalMappingRuleMap
Dim externalRelationshipRuleMap

Dim unmappedTagCounts
Dim unknownElementTypeCounts
Dim unknownRelationshipTypeCounts
Dim invalidTypedValueCounts
Dim relationshipEndpointMismatchCounts
Dim legacyElementMigrationCounts
Dim legacyPropertyMigrationCounts
Dim legacyRelationshipMigrationCounts
Dim ambiguousRelationshipCounts
Dim satisfactionConversionCounts
Dim externalProfileCounts
Dim externalMetaTypeCounts
Dim externalStereotypeCounts
Dim externalElementMappingCounts
Dim externalRelationshipProfileCounts
Dim externalRelationshipMappingCounts
Dim trustedElementTransformationCounts
Dim trustedRelationshipTransformationCounts
Dim trustedRelationshipNoEquivalentCounts

Dim rootPackage
Dim rootGuid
Dim modelPrefixBase
Dim outputFile
Dim reportFile

Dim packageCount
Dim elementCount
Dim relationshipCount
Dim projectionCount
Dim genericConnectorCount
Dim suppressedIdTagCount
Dim mappedPropertyValueCount
Dim rawTaggedValueCount
Dim unresolvedObjectReferenceCount
Dim externalConnectorCount
Dim externalEndpointCount
Dim unnamedElementCount
Dim semanticRelationshipCount
Dim relationshipResolvedExactCount
Dim relationshipResolvedByEndpointsCount
Dim relationshipDirectionReversedCount
Dim ambiguousRelationshipCount
Dim externalRelationshipCount
Dim externalElementMappingCount
Dim externalRelationshipMappingCount
Dim externalFQStereotypeCount
Dim externalConnectorFQStereotypeCount
Dim externalAppliedElementTransformationCount
Dim externalAppliedRelationshipTransformationCount
Dim externalCandidateElementMappingCount
Dim externalCandidateRelationshipMappingCount

Sub Main()
    InitState
    InitMetamodelMaps

    Session.Output "DAF 6.3 M1 RDF Model Exporter v" & EXPORTER_VERSION
    Session.Output "Semantic metamodel mapping contract: " & METAMODEL_EXPORT_VERSION
    Session.Output ""

    Set rootPackage = Repository.GetTreeSelectedPackage()

    If rootPackage Is Nothing Then
        Session.Output "ERROR: Select the root DAF package in the Project Browser and run the script again."
        Exit Sub
    End If

    rootGuid = NormalizeGuid(rootPackage.PackageGUID)
    modelPrefixBase = "urn:daf:model:" & rootGuid & "#"

    Dim defaultFile
    defaultFile = "C:\tmp\DAF-" & SafeFileName(rootPackage.Name) & "-model.ttl"

    outputFile = InputBox( _
        "Turtle output file for DAF " & DAF_VERSION & " model '" & rootPackage.Name & "':", _
        "DAF M1 RDF Export", _
        defaultFile)

    If Trim(CStr(outputFile)) = "" Then
        Session.Output "Export cancelled."
        Exit Sub
    End If

    EnsureParentFolder outputFile
    reportFile = ReplaceExtension(outputFile, ".report.txt")

    OpenStreams

    WriteHeader

    ' Two-pass export:
    ' 1. collect packages/elements so all GUID -> IRI mappings are known
    ' 2. serialize packages/elements/relationships
    CollectPackage rootPackage

    WritePackageTree rootPackage, ""
    WritePackageElements rootPackage

    WriteAuditSummary
    CloseStreams

    Session.Output ""
    Session.Output "Export complete."
    Session.Output "RDF:    " & outputFile
    Session.Output "Report: " & reportFile
    Session.Output "Elements: " & elementCount & "; relationships: " & relationshipCount & "; packages: " & packageCount
End Sub

Sub InitState()
    Set classMap = CreateObject("Scripting.Dictionary")
    classMap.CompareMode = 1

    Set propertyMap = CreateObject("Scripting.Dictionary")
    propertyMap.CompareMode = 1

    Set relationshipMap = CreateObject("Scripting.Dictionary")
    relationshipMap.CompareMode = 1

    Set relationshipSourceMap = CreateObject("Scripting.Dictionary")
    relationshipSourceMap.CompareMode = 1

    Set relationshipTargetMap = CreateObject("Scripting.Dictionary")
    relationshipTargetMap.CompareMode = 1

    Set relationshipPairMap = CreateObject("Scripting.Dictionary")
    relationshipPairMap.CompareMode = 1

    Set classParentMap = CreateObject("Scripting.Dictionary")
    classParentMap.CompareMode = 1

    Set legacyElementTypeMap = CreateObject("Scripting.Dictionary")
    legacyElementTypeMap.CompareMode = 1

    Set legacyElementInjectedPropertyMap = CreateObject("Scripting.Dictionary")
    legacyElementInjectedPropertyMap.CompareMode = 1

    Set legacyPropertyAliasMap = CreateObject("Scripting.Dictionary")
    legacyPropertyAliasMap.CompareMode = 1

    Set packageIriById = CreateObject("Scripting.Dictionary")
    packageIriById.CompareMode = 1

    Set elementIriById = CreateObject("Scripting.Dictionary")
    elementIriById.CompareMode = 1

    Set elementIriByGuid = CreateObject("Scripting.Dictionary")
    elementIriByGuid.CompareMode = 1

    Set elementStereoById = CreateObject("Scripting.Dictionary")
    elementStereoById.CompareMode = 1

    Set elementSourceStereoById = CreateObject("Scripting.Dictionary")
    elementSourceStereoById.CompareMode = 1

    Set exportedConnectorGuids = CreateObject("Scripting.Dictionary")
    exportedConnectorGuids.CompareMode = 1

    Set externalEndpointIriById = CreateObject("Scripting.Dictionary")
    externalEndpointIriById.CompareMode = 1

    Set externalEndpointTypeById = CreateObject("Scripting.Dictionary")
    externalEndpointTypeById.CompareMode = 1

    Set externalEndpointWrittenById = CreateObject("Scripting.Dictionary")
    externalEndpointWrittenById.CompareMode = 1

    Set externalMappedDAFTypeById = CreateObject("Scripting.Dictionary")
    externalMappedDAFTypeById.CompareMode = 1

    Set externalMappedDAFStatusById = CreateObject("Scripting.Dictionary")
    externalMappedDAFStatusById.CompareMode = 1

    Set externalSourceProfileById = CreateObject("Scripting.Dictionary")
    externalSourceProfileById.CompareMode = 1

    Set externalMappingRuleMap = CreateObject("Scripting.Dictionary")
    externalMappingRuleMap.CompareMode = 1

    Set externalRelationshipRuleMap = CreateObject("Scripting.Dictionary")
    externalRelationshipRuleMap.CompareMode = 1

    Set unmappedTagCounts = CreateObject("Scripting.Dictionary")
    unmappedTagCounts.CompareMode = 1

    Set unknownElementTypeCounts = CreateObject("Scripting.Dictionary")
    unknownElementTypeCounts.CompareMode = 1

    Set unknownRelationshipTypeCounts = CreateObject("Scripting.Dictionary")
    unknownRelationshipTypeCounts.CompareMode = 1

    Set invalidTypedValueCounts = CreateObject("Scripting.Dictionary")
    invalidTypedValueCounts.CompareMode = 1

    Set relationshipEndpointMismatchCounts = CreateObject("Scripting.Dictionary")
    relationshipEndpointMismatchCounts.CompareMode = 1

    Set legacyElementMigrationCounts = CreateObject("Scripting.Dictionary")
    legacyElementMigrationCounts.CompareMode = 1

    Set legacyPropertyMigrationCounts = CreateObject("Scripting.Dictionary")
    legacyPropertyMigrationCounts.CompareMode = 1

    Set legacyRelationshipMigrationCounts = CreateObject("Scripting.Dictionary")
    legacyRelationshipMigrationCounts.CompareMode = 1

    Set ambiguousRelationshipCounts = CreateObject("Scripting.Dictionary")
    ambiguousRelationshipCounts.CompareMode = 1

    Set satisfactionConversionCounts = CreateObject("Scripting.Dictionary")
    satisfactionConversionCounts.CompareMode = 1

    Set externalProfileCounts = CreateObject("Scripting.Dictionary")
    externalProfileCounts.CompareMode = 1

    Set externalMetaTypeCounts = CreateObject("Scripting.Dictionary")
    externalMetaTypeCounts.CompareMode = 1

    Set externalStereotypeCounts = CreateObject("Scripting.Dictionary")
    externalStereotypeCounts.CompareMode = 1

    Set externalElementMappingCounts = CreateObject("Scripting.Dictionary")
    externalElementMappingCounts.CompareMode = 1

    Set externalRelationshipProfileCounts = CreateObject("Scripting.Dictionary")
    externalRelationshipProfileCounts.CompareMode = 1

    Set externalRelationshipMappingCounts = CreateObject("Scripting.Dictionary")
    externalRelationshipMappingCounts.CompareMode = 1

    Set trustedElementTransformationCounts = CreateObject("Scripting.Dictionary")
    trustedElementTransformationCounts.CompareMode = 1

    Set trustedRelationshipTransformationCounts = CreateObject("Scripting.Dictionary")
    trustedRelationshipTransformationCounts.CompareMode = 1

    Set trustedRelationshipNoEquivalentCounts = CreateObject("Scripting.Dictionary")
    trustedRelationshipNoEquivalentCounts.CompareMode = 1

    packageCount = 0
    elementCount = 0
    relationshipCount = 0
    projectionCount = 0
    genericConnectorCount = 0
    suppressedIdTagCount = 0
    mappedPropertyValueCount = 0
    rawTaggedValueCount = 0
    unresolvedObjectReferenceCount = 0
    externalConnectorCount = 0
    externalEndpointCount = 0
    unnamedElementCount = 0
    semanticRelationshipCount = 0
    relationshipResolvedExactCount = 0
    relationshipResolvedByEndpointsCount = 0
    relationshipDirectionReversedCount = 0
    ambiguousRelationshipCount = 0
    externalRelationshipCount = 0
    externalElementMappingCount = 0
    externalRelationshipMappingCount = 0
    externalFQStereotypeCount = 0
    externalConnectorFQStereotypeCount = 0
    externalAppliedElementTransformationCount = 0
    externalAppliedRelationshipTransformationCount = 0
    externalCandidateElementMappingCount = 0
    externalCandidateRelationshipMappingCount = 0
End Sub

Sub InitMetamodelMaps()
    AddClass "dAPI"
    AddClass "dAPIOperation"
    AddClass "dAPIParameter"
    AddClass "dAPIResponse"
    AddClass "dAction"
    AddClass "dActivity"
    AddClass "dActor"
    AddClass "dApplicationComponent"
    AddClass "dApplicationFunction"
    AddClass "dBusinessArea"
    AddClass "dBusinessProcess"
    AddClass "dBusinessService"
    AddClass "dBusinessUseCase"
    AddClass "dCapability"
    AddClass "dCluster"
    AddClass "dContainer"
    AddClass "dController"
    AddClass "dDataEntity"
    AddClass "dDecision"
    AddClass "dDeploymentModel"
    AddClass "dDeploymentNode"
    AddClass "dEvent"
    AddClass "dFeature"
    AddClass "dGoal"
    AddClass "dGrowthPackage"
    AddClass "dIPRange"
    AddClass "dInitiative"
    AddClass "dIssue"
    AddClass "dJSON_Attribute"
    AddClass "dJSON_Datatype"
    AddClass "dJSON_Element"
    AddClass "dJSON_Schema"
    AddClass "dJSON_SchemaSubSet"
    AddClass "dJSON_Type"
    AddClass "dLocation"
    AddClass "dLogicalAppComponent"
    AddClass "dMeasurementArea"
    AddClass "dMeasurementCategory"
    AddClass "dMeasurementGrouping"
    AddClass "dMeasurementIndicator"
    AddClass "dModelClass"
    AddClass "dNetwork"
    AddClass "dObject"
    AddClass "dObjective"
    AddClass "dOnPremise"
    AddClass "dOpinion"
    AddClass "dOpinionInner"
    AddClass "dOrganizationUnit"
    AddClass "dPhysicalService"
    AddClass "dPrinciple"
    AddClass "dProduct"
    AddClass "dProgram"
    AddClass "dPublicCluster"
    AddClass "dRegion"
    AddClass "dRequirement"
    AddClass "dResource"
    AddClass "dRisk"
    AddClass "dRole"
    AddClass "dSecurityGroup"
    AddClass "dSkill"
    AddClass "dStakeholder"
    AddClass "dSubNetwork"
    AddClass "dSystem"
    AddClass "dTable"
    AddClass "dTest"
    AddClass "dUserStory"
    AddClass "dValue"
    AddClass "dValueRef"
    AddClass "dValueStream"
    AddClass "dView"
    AddClass "dVolume"
    AddClass "dZone"

    AddProperty "dActor", "#FTEs", "dActor___FTEs", "literal", "int"
    AddProperty "dActor", "ActorGoal", "dActor__ActorGoal", "literal", "string"
    AddProperty "dActor", "ActorTasks", "dActor__ActorTasks", "literal", "string"
    AddProperty "dActor", "ActorType", "dActor__ActorType", "literal", "string"
    AddProperty "dAPI", "basePath", "dAPI__basePath", "literal", "string"
    AddProperty "dAPI", "consumes", "dAPI__consumes", "literal", "string"
    AddProperty "dAPI", "contact", "dAPI__contact", "object", "https://freetakteam.github.io/DAF/definition#ExternalClassifier_Contact_77AAD348"
    AddProperty "dAPI", "definitions", "dAPI__definitions", "literal", "string"
    AddProperty "dAPI", "Full Name", "dAPI__Full_Name", "literal", "string"
    AddProperty "dAPI", "host", "dAPI__host", "literal", "string"
    AddProperty "dAPI", "license", "dAPI__license", "literal", "string"
    AddProperty "dAPI", "parameters", "dAPI__parameters", "literal", "string"
    AddProperty "dAPI", "produces", "dAPI__produces", "literal", "string"
    AddProperty "dAPI", "responses", "dAPI__responses", "literal", "string"
    AddProperty "dAPI", "schemes", "dAPI__schemes", "literal", "string"
    AddProperty "dAPI", "securityDefinitions", "dAPI__securityDefinitions", "literal", "string"
    AddProperty "dAPI", "swagger", "dAPI__swagger", "literal", "string"
    AddProperty "dAPI", "tags", "dAPI__tags", "literal", "string"
    AddProperty "dAPIOperation", "base_Operation", "dAPIOperation__base_Operation", "literal", "string"
    AddProperty "dAPIOperation", "consumes", "dAPIOperation__consumes", "literal", "string"
    AddProperty "dAPIOperation", "deprecated", "dAPIOperation__deprecated", "literal", "string"
    AddProperty "dAPIOperation", "description", "dAPIOperation__description", "literal", "string"
    AddProperty "dAPIOperation", "hTTPMethod", "dAPIOperation__hTTPMethod", "literal", "string"
    AddProperty "dAPIOperation", "produces", "dAPIOperation__produces", "literal", "string"
    AddProperty "dAPIOperation", "relativePath", "dAPIOperation__relativePath", "literal", "string"
    AddProperty "dAPIOperation", "schemes", "dAPIOperation__schemes", "literal", "string"
    AddProperty "dAPIOperation", "summary", "dAPIOperation__summary", "literal", "string"
    AddProperty "dAPIOperation", "tags", "dAPIOperation__tags", "literal", "string"
    AddProperty "dAPIParameter", "allowEmptyValue", "dAPIParameter__allowEmptyValue", "literal", "string"
    AddProperty "dAPIParameter", "base_Parameter", "dAPIParameter__base_Parameter", "literal", "string"
    AddProperty "dAPIParameter", "collectionFormat", "dAPIParameter__collectionFormat", "literal", "string"
    AddProperty "dAPIParameter", "location", "dAPIParameter__location", "literal", "string"
    AddProperty "dAPIParameter", "required", "dAPIParameter__required", "literal", "string"
    AddProperty "dAPIResponse", "base_Parameter", "dAPIResponse__base_Parameter", "literal", "string"
    AddProperty "dAPIResponse", "default", "dAPIResponse__default", "literal", "string"
    AddProperty "dAPIResponse", "examples", "dAPIResponse__examples", "literal", "string"
    AddProperty "dAPIResponse", "headers", "dAPIResponse__headers", "literal", "string"
    AddProperty "dAPIResponse", "Integer", "dAPIResponse__Integer", "literal", "int"
    AddProperty "dApplicationComponent", "ApplicationType", "dApplicationComponent__ApplicationType", "literal", "string"
    AddProperty "dApplicationComponent", "BizCriticality", "dApplicationComponent__BizCriticality", "literal", "int"
    AddProperty "dApplicationComponent", "BizSatisfaction", "dApplicationComponent__BizSatisfaction", "literal", "int"
    AddProperty "dApplicationComponent", "Category", "dApplicationComponent__Category", "literal", "string"
    AddProperty "dApplicationComponent", "Cost", "dApplicationComponent__Cost", "literal", "int"
    AddProperty "dApplicationComponent", "InvestmentStrategy", "dApplicationComponent__InvestmentStrategy", "literal", "string"
    AddProperty "dApplicationComponent", "ITSatisfaction", "dApplicationComponent__ITSatisfaction", "literal", "int"
    AddProperty "dApplicationComponent", "LastStandardReviewDate", "dApplicationComponent__LastStandardReviewDate", "literal", "string"
    AddProperty "dApplicationComponent", "NextStandardReviewDate", "dApplicationComponent__NextStandardReviewDate", "literal", "string"
    AddProperty "dApplicationComponent", "Owner", "dApplicationComponent__Owner", "literal", "string"
    AddProperty "dApplicationComponent", "Port", "dApplicationComponent__Port", "literal", "string"
    AddProperty "dApplicationComponent", "RetireDate", "dApplicationComponent__RetireDate", "literal", "string"
    AddProperty "dApplicationComponent", "Source", "dApplicationComponent__Source", "literal", "string"
    AddProperty "dBusinessProcess", "Category", "dBusinessProcess__Category", "literal", "string"
    AddProperty "dBusinessProcess", "isAdopted", "dBusinessProcess__isAdopted", "literal", "boolean"
    AddProperty "dBusinessProcess", "isDocumented", "dBusinessProcess__isDocumented", "literal", "boolean"
    AddProperty "dBusinessProcess", "isEffective", "dBusinessProcess__isEffective", "literal", "boolean"
    AddProperty "dBusinessProcess", "isOptimized", "dBusinessProcess__isOptimized", "literal", "boolean"
    AddProperty "dBusinessProcess", "LastStandardReviewDate", "dBusinessProcess__LastStandardReviewDate", "literal", "dateTime"
    AddProperty "dBusinessProcess", "NextStandardReviewDate", "dBusinessProcess__NextStandardReviewDate", "literal", "dateTime"
    AddProperty "dBusinessProcess", "Owner", "dBusinessProcess__Owner", "literal", "string"
    AddProperty "dBusinessProcess", "ProcessCriticality", "dBusinessProcess__ProcessCriticality", "literal", "string"
    AddProperty "dBusinessProcess", "ProcessType", "dBusinessProcess__ProcessType", "literal", "string"
    AddProperty "dBusinessProcess", "ProcessVolumetrics", "dBusinessProcess__ProcessVolumetrics", "literal", "string"
    AddProperty "dBusinessProcess", "RetireDate", "dBusinessProcess__RetireDate", "literal", "dateTime"
    AddProperty "dBusinessProcess", "Source", "dBusinessProcess__Source", "literal", "string"
    AddProperty "dBusinessProcess", "StandardCreationDate", "dBusinessProcess__StandardCreationDate", "literal", "date"
    AddProperty "dBusinessService", "Category", "dBusinessService__Category", "literal", "string"
    AddProperty "dBusinessService", "LastStandardReviewDate", "dBusinessService__LastStandardReviewDate", "literal", "date"
    AddProperty "dBusinessService", "NextStandardReviewDate", "dBusinessService__NextStandardReviewDate", "literal", "date"
    AddProperty "dBusinessService", "Owner", "dBusinessService__Owner", "literal", "string"
    AddProperty "dBusinessService", "RetireDate", "dBusinessService__RetireDate", "literal", "date"
    AddProperty "dBusinessService", "Source", "dBusinessService__Source", "literal", "string"
    AddProperty "dBusinessUseCase", "Extensions", "dBusinessUseCase__Extensions", "literal", "string"
    AddProperty "dBusinessUseCase", "GoalInContext", "dBusinessUseCase__GoalInContext", "literal", "string"
    AddProperty "dBusinessUseCase", "isCore", "dBusinessUseCase__isCore", "literal", "boolean"
    AddProperty "dBusinessUseCase", "Level", "dBusinessUseCase__Level", "literal", "string"
    AddProperty "dBusinessUseCase", "MainSuccessScenario", "dBusinessUseCase__MainSuccessScenario", "literal", "string"
    AddProperty "dBusinessUseCase", "OtherActors", "dBusinessUseCase__OtherActors", "literal", "string"
    AddProperty "dBusinessUseCase", "Precondition", "dBusinessUseCase__Precondition", "literal", "string"
    AddProperty "dBusinessUseCase", "Scope", "dBusinessUseCase__Scope", "literal", "string"
    AddProperty "dBusinessUseCase", "Trigger", "dBusinessUseCase__Trigger", "literal", "string"
    AddProperty "dCapability", "BusinessValue", "dCapability__BusinessValue", "literal", "string"
    AddProperty "dCapability", "Category", "dCapability__Category", "literal", "string"
    AddProperty "dCapability", "Cost", "dCapability__Cost", "literal", "float"
    AddProperty "dCapability", "Criticality", "dCapability__Criticality", "literal", "int"
    AddProperty "dCapability", "Increments", "dCapability__Increments", "literal", "string"
    AddProperty "dCapability", "IncrementsToBe", "dCapability__IncrementsToBe", "literal", "string"
    AddProperty "dCapability", "IncrementSupplyChain", "dCapability__IncrementSupplyChain", "literal", "string"
    AddProperty "dCapability", "IncrementVertical", "dCapability__IncrementVertical", "literal", "string"
    AddProperty "dCapability", "Owner", "dCapability__Owner", "literal", "string"
    AddProperty "dCapability", "Risk", "dCapability__Risk", "literal", "int"
    AddProperty "dCapability", "Source", "dCapability__Source", "literal", "string"
    AddProperty "dDataEntity", "Category", "dDataEntity__Category", "literal", "string"
    AddProperty "dDataEntity", "isAccessible", "dDataEntity__isAccessible", "literal", "boolean"
    AddProperty "dDataEntity", "isAccurate", "dDataEntity__isAccurate", "literal", "boolean"
    AddProperty "dDataEntity", "isTimely", "dDataEntity__isTimely", "literal", "boolean"
    AddProperty "dDataEntity", "Owner", "dDataEntity__Owner", "literal", "string"
    AddProperty "dDataEntity", "PrivacyClassification", "dDataEntity__PrivacyClassification", "literal", "string"
    AddProperty "dDataEntity", "RetentionClassification", "dDataEntity__RetentionClassification", "literal", "string"
    AddProperty "dDataEntity", "Source", "dDataEntity__Source", "literal", "string"
    AddProperty "dDecision", "Alternatives", "dDecision__Alternatives", "literal", "string"
    AddProperty "dDecision", "Assumptions", "dDecision__Assumptions", "literal", "string"
    AddProperty "dDecision", "Decision", "dDecision__Decision", "literal", "string"
    AddProperty "dDecision", "Implications", "dDecision__Implications", "literal", "string"
    AddProperty "dDecision", "Justification", "dDecision__Justification", "literal", "string"
    AddProperty "dDecision", "Motivation", "dDecision__Motivation", "literal", "string"
    AddProperty "dDecision", "RelatedDecisions", "dDecision__RelatedDecisions", "object", "https://freetakteam.github.io/DAF/model#dDecision"
    AddProperty "dDecision", "Subject Area", "dDecision__Subject_Area", "literal", "string"
    AddProperty "dDecision", "Topic", "dDecision__Topic", "literal", "string"
    AddProperty "dDeploymentNode", "ArchitectureType", "dDeploymentNode__ArchitectureType", "literal", "string"
    AddProperty "dDeploymentNode", "CPU", "dDeploymentNode__CPU", "literal", "string"
    AddProperty "dDeploymentNode", "Disk", "dDeploymentNode__Disk", "literal", "string"
    AddProperty "dDeploymentNode", "hostname", "dDeploymentNode__hostname", "literal", "string"
    AddProperty "dDeploymentNode", "IP", "dDeploymentNode__IP", "literal", "string"
    AddProperty "dDeploymentNode", "OS", "dDeploymentNode__OS", "literal", "string"
    AddProperty "dDeploymentNode", "Owner", "dDeploymentNode__Owner", "literal", "string"
    AddProperty "dDeploymentNode", "PublicIP", "dDeploymentNode__PublicIP", "literal", "string"
    AddProperty "dDeploymentNode", "RAM", "dDeploymentNode__RAM", "literal", "string"
    AddProperty "dEvent", "Category", "dEvent__Category", "literal", "string"
    AddProperty "dEvent", "Owner", "dEvent__Owner", "literal", "string"
    AddProperty "dEvent", "Source", "dEvent__Source", "literal", "string"
    AddProperty "dFeature", "Author", "dFeature__Author", "literal", "string"
    AddProperty "dFeature", "isImplemented", "dFeature__isImplemented", "literal", "boolean"
    AddProperty "dFeature", "Proofreader", "dFeature__Proofreader", "literal", "string"
    AddProperty "dGoal", "dAssumption", "dGoal__dAssumption", "literal", "string"
    AddProperty "dGoal", "Priority", "dGoal__Priority", "literal", "int"
    AddProperty "dGoal", "Value_amount", "dGoal__Value_amount", "literal", "string"
    AddProperty "dGoal", "Value_Goal", "dGoal__Value_Goal", "literal", "string"
    AddProperty "dGoal", "Value_Name", "dGoal__Value_Name", "literal", "string"
    AddProperty "dInitiative", "ability to Implement", "dInitiative__ability_to_Implement", "literal", "int"
    AddProperty "dInitiative", "Benefit", "dInitiative__Benefit", "literal", "int"
    AddProperty "dInitiative", "Description", "dInitiative__Description", "literal", "string"
    AddProperty "dInitiative", "DetailedDescription", "dInitiative__DetailedDescription", "literal", "string"
    AddProperty "dInitiative", "finishDate", "dInitiative__finishDate", "literal", "dateTime"
    AddProperty "dInitiative", "Impacted Capability", "dInitiative__Impacted_Capability", "object", "https://freetakteam.github.io/DAF/model#dCapability"
    AddProperty "dInitiative", "InitiativeDuration", "dInitiative__InitiativeDuration", "literal", "string"
    AddProperty "dInitiative", "kind", "dInitiative__kind", "literal", "string"
    AddProperty "dInitiative", "purpose", "dInitiative__purpose", "literal", "string"
    AddProperty "dInitiative", "Rank", "dInitiative__Rank", "literal", "string"
    AddProperty "dInitiative", "RelatedProgram", "dInitiative__RelatedProgram", "literal", "string"
    AddProperty "dInitiative", "startDate", "dInitiative__startDate", "literal", "dateTime"
    AddProperty "dIPRange", "CIDR", "dIPRange__CIDR", "literal", "string"
    AddProperty "dIPRange", "ipRangeType", "dIPRange__ipRangeType", "literal", "string"
    AddProperty "dIPRange", "Public", "dIPRange__Public", "literal", "string"
    AddProperty "dIssue", "Author", "dIssue__Author", "literal", "string"
    AddProperty "dIssue", "Responsible", "dIssue__Responsible", "literal", "string"
    AddProperty "dJSON_Attribute", "jSONtype", "dJSON_Attribute__jSONtype", "object", "https://freetakteam.github.io/DAF/model#dJSON_Type"
    AddProperty "dJSON_Schema", "schema", "dJSON_Schema__schema", "literal", "string"
    AddProperty "dJSON_Schema", "schemaFileName", "dJSON_Schema__schemaFileName", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "default", "dJSON_SchemaSubSet__default", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "enum", "dJSON_SchemaSubSet__enum", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "exclusivemaximum", "dJSON_SchemaSubSet__exclusivemaximum", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "exclusiveminimum", "dJSON_SchemaSubSet__exclusiveminimum", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "format", "dJSON_SchemaSubSet__format", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "maximum", "dJSON_SchemaSubSet__maximum", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "maxItems", "dJSON_SchemaSubSet__maxItems", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "maxlength", "dJSON_SchemaSubSet__maxlength", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "maxProperties", "dJSON_SchemaSubSet__maxProperties", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "minimum", "dJSON_SchemaSubSet__minimum", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "minItems", "dJSON_SchemaSubSet__minItems", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "minlength", "dJSON_SchemaSubSet__minlength", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "minProperties", "dJSON_SchemaSubSet__minProperties", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "multipleof", "dJSON_SchemaSubSet__multipleof", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "pattern", "dJSON_SchemaSubSet__pattern", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "required", "dJSON_SchemaSubSet__required", "literal", "string"
    AddProperty "dJSON_SchemaSubSet", "uniqueItems", "dJSON_SchemaSubSet__uniqueItems", "literal", "string"
    AddProperty "dJSON_Type", "enum", "dJSON_Type__enum", "literal", "string"
    AddProperty "dJSON_Type", "exclusivemaximum", "dJSON_Type__exclusivemaximum", "literal", "string"
    AddProperty "dJSON_Type", "exclusiveminimum", "dJSON_Type__exclusiveminimum", "literal", "string"
    AddProperty "dJSON_Type", "format", "dJSON_Type__format", "literal", "string"
    AddProperty "dJSON_Type", "maximum", "dJSON_Type__maximum", "literal", "string"
    AddProperty "dJSON_Type", "maxlength", "dJSON_Type__maxlength", "literal", "string"
    AddProperty "dJSON_Type", "minimum", "dJSON_Type__minimum", "literal", "int"
    AddProperty "dJSON_Type", "minlength", "dJSON_Type__minlength", "literal", "int"
    AddProperty "dJSON_Type", "multipleof", "dJSON_Type__multipleof", "literal", "string"
    AddProperty "dJSON_Type", "pattern", "dJSON_Type__pattern", "literal", "string"
    AddProperty "dLocation", "AreaCode", "dLocation__AreaCode", "literal", "string"
    AddProperty "dLocation", "City", "dLocation__City", "literal", "string"
    AddProperty "dLocation", "Country", "dLocation__Country", "literal", "string"
    AddProperty "dLocation", "EmailID", "dLocation__EmailID", "literal", "string"
    AddProperty "dLocation", "PhoneNumber", "dLocation__PhoneNumber", "literal", "string"
    AddProperty "dLocation", "Province", "dLocation__Province", "literal", "string"
    AddProperty "dLocation", "Street", "dLocation__Street", "literal", "string"
    AddProperty "dLogicalAppComponent", "isMeetingBusinessNeeds", "dLogicalAppComponent__isMeetingBusinessNeeds", "literal", "boolean"
    AddProperty "dLogicalAppComponent", "isMeetingFutureNeeds", "dLogicalAppComponent__isMeetingFutureNeeds", "literal", "boolean"
    AddProperty "dLogicalAppComponent", "isUsable", "dLogicalAppComponent__isUsable", "literal", "boolean"
    AddProperty "dMeasurementArea", "Definition", "dMeasurementArea__Definition", "literal", "string"
    AddProperty "dMeasurementCategory", "Definition", "dMeasurementCategory__Definition", "literal", "string"
    AddProperty "dMeasurementCategory", "MeasurementArea", "dMeasurementCategory__MeasurementArea", "object", "https://freetakteam.github.io/DAF/model#dMeasurementArea"
    AddProperty "dMeasurementGrouping", "Definition", "dMeasurementGrouping__Definition", "literal", "string"
    AddProperty "dMeasurementGrouping", "MeasurementCategory", "dMeasurementGrouping__MeasurementCategory", "object", "https://freetakteam.github.io/DAF/model#dMeasurementCategory"
    AddProperty "dMeasurementIndicator", "CurrentLevel", "dMeasurementIndicator__CurrentLevel", "literal", "string"
    AddProperty "dMeasurementIndicator", "Definition", "dMeasurementIndicator__Definition", "literal", "string"
    AddProperty "dMeasurementIndicator", "LastStandardReviewDate", "dMeasurementIndicator__LastStandardReviewDate", "literal", "dateTime"
    AddProperty "dMeasurementIndicator", "SatisfactionLevel", "dMeasurementIndicator__SatisfactionLevel", "literal", "string"
    AddProperty "dMeasurementIndicator", "UnitOfMeasure", "dMeasurementIndicator__UnitOfMeasure", "literal", "string"
    AddProperty "dModelClass", "_metatype", "dModelClass___metatype", "literal", "string"
    AddProperty "dModelClass", "child_order", "dModelClass__child_order", "literal", "string"
    AddProperty "dModelClass", "display_value", "dModelClass__display_value", "literal", "string"
    AddProperty "dModelClass", "initparams", "dModelClass__initparams", "literal", "string"
    AddProperty "dModelClass", "is_searchable", "dModelClass__is_searchable", "literal", "boolean"
    AddProperty "dModelClass", "is_soap", "dModelClass__is_soap", "literal", "boolean"
    AddProperty "dModelClass", "orderby", "dModelClass__orderby", "literal", "string"
    AddProperty "dModelClass", "parent_order", "dModelClass__parent_order", "literal", "string"
    AddProperty "dModelClass", "pk_name", "dModelClass__pk_name", "literal", "string"
    AddProperty "dModelClass", "table_name", "dModelClass__table_name", "literal", "string"
    AddProperty "dNetwork", "NetworkQuality", "dNetwork__NetworkQuality", "literal", "string"
    AddProperty "dNetwork", "NetworkType", "dNetwork__NetworkType", "literal", "string"
    AddProperty "dObjective", "Category", "dObjective__Category", "literal", "string"
    AddProperty "dObjective", "finishDate", "dObjective__finishDate", "literal", "date"
    AddProperty "dObjective", "Owner", "dObjective__Owner", "literal", "string"
    AddProperty "dObjective", "Source", "dObjective__Source", "literal", "string"
    AddProperty "dOrganizationUnit", "HeadCount", "dOrganizationUnit__HeadCount", "literal", "string"
    AddProperty "dPhysicalService", "Category", "dPhysicalService__Category", "literal", "string"
    AddProperty "dPhysicalService", "execution_mode", "dPhysicalService__execution_mode", "literal", "string"
    AddProperty "dPhysicalService", "LastStandardReviewDate", "dPhysicalService__LastStandardReviewDate", "literal", "date"
    AddProperty "dPhysicalService", "NextStandardReviewDate", "dPhysicalService__NextStandardReviewDate", "literal", "string"
    AddProperty "dPhysicalService", "Owner", "dPhysicalService__Owner", "literal", "string"
    AddProperty "dPhysicalService", "port", "dPhysicalService__port", "literal", "string"
    AddProperty "dPhysicalService", "protocol", "dPhysicalService__protocol", "literal", "string"
    AddProperty "dPhysicalService", "RetireDate", "dPhysicalService__RetireDate", "literal", "dateTime"
    AddProperty "dPhysicalService", "Source", "dPhysicalService__Source", "literal", "string"
    AddProperty "dPrinciple", "Implications", "dPrinciple__Implications", "literal", "string"
    AddProperty "dPrinciple", "Owner", "dPrinciple__Owner", "object", "https://freetakteam.github.io/DAF/model#dStakeholder"
    AddProperty "dPrinciple", "PrincipleID", "dPrinciple__PrincipleID", "literal", "string"
    AddProperty "dPrinciple", "PrincipleMeasurement", "dPrinciple__PrincipleMeasurement", "object", "https://freetakteam.github.io/DAF/model#dMeasurementIndicator"
    AddProperty "dPrinciple", "Priority", "dPrinciple__Priority", "literal", "string"
    AddProperty "dPrinciple", "Rationale", "dPrinciple__Rationale", "literal", "string"
    AddProperty "dPrinciple", "Source", "dPrinciple__Source", "literal", "string"
    AddProperty "dPrinciple", "Statement", "dPrinciple__Statement", "literal", "string"
    AddProperty "dPrinciple", "Type", "dPrinciple__Type", "literal", "string"
    AddProperty "dProduct", "Owner", "dProduct__Owner", "literal", "string"
    AddProperty "dProduct", "Price", "dProduct__Price", "literal", "string"
    AddProperty "dProduct", "RetireDate", "dProduct__RetireDate", "literal", "string"
    AddProperty "dProduct", "Source", "dProduct__Source", "literal", "string"
    AddProperty "dPublicCluster", "configFile", "dPublicCluster__configFile", "literal", "string"
    AddProperty "dPublicCluster", "NodeNum", "dPublicCluster__NodeNum", "literal", "string"
    AddProperty "dPublicCluster", "provider", "dPublicCluster__provider", "literal", "string"
    AddProperty "dRequirement", "Author", "dRequirement__Author", "literal", "string"
    AddProperty "dRequirement", "Priority", "dRequirement__Priority", "literal", "int"
    AddProperty "dRequirement", "Proofreader", "dRequirement__Proofreader", "literal", "string"
    AddProperty "dRequirement", "Status", "dRequirement__Status", "literal", "string"
    AddProperty "dRequirement", "Type", "dRequirement__Type", "literal", "string"
    AddProperty "dResource", "# of items", "dResource___of_items", "literal", "string"
    AddProperty "dRisk", "Likehood", "dRisk__Likehood", "literal", "string"
    AddProperty "dRisk", "RiskStrategy", "dRisk__RiskStrategy", "literal", "string"
    AddProperty "dRisk", "Severity", "dRisk__Severity", "literal", "string"
    AddProperty "dRole", "#FTEs", "dRole___FTEs", "literal", "string"
    AddProperty "dRole", "Cost", "dRole__Cost", "literal", "string"
    AddProperty "dRole", "DegreeOfUtilisation", "dRole__DegreeOfUtilisation", "literal", "string"
    AddProperty "dRole", "isSkillsAvailable", "dRole__isSkillsAvailable", "literal", "boolean"
    AddProperty "dRole", "isSkillsDefined", "dRole__isSkillsDefined", "literal", "boolean"
    AddProperty "dRole", "Owner", "dRole__Owner", "literal", "string"
    AddProperty "dRole", "Source", "dRole__Source", "literal", "string"
    AddProperty "dRole", "User", "dRole__User", "literal", "string"
    AddProperty "dSkill", "SkillCategory", "dSkill__SkillCategory", "literal", "string"
    AddProperty "dSkill", "SkillLevel", "dSkill__SkillLevel", "literal", "string"
    AddProperty "dStakeholder", "Attitude", "dStakeholder__Attitude", "literal", "string"
    AddProperty "dStakeholder", "Knowledge", "dStakeholder__Knowledge", "literal", "string"
    AddProperty "dStakeholder", "Legitimacy", "dStakeholder__Legitimacy", "literal", "string"
    AddProperty "dStakeholder", "Power", "dStakeholder__Power", "literal", "string"
    AddProperty "dStakeholder", "RACI", "dStakeholder__RACI", "literal", "string"
    AddProperty "dStakeholder", "role", "dStakeholder__role", "object", "https://freetakteam.github.io/DAF/model#dRole"
    AddProperty "dStakeholder", "Urgency", "dStakeholder__Urgency", "literal", "string"
    AddProperty "dSystem", "config", "dSystem__config", "literal", "string"
    AddProperty "dSystem", "plattform", "dSystem__plattform", "literal", "string"
    AddProperty "dTable", "Database", "dTable__Database", "literal", "string"
    AddProperty "dUserStory", "EstimatedEffort", "dUserStory__EstimatedEffort", "literal", "string"
    AddProperty "dUserStory", "StoryDetails", "dUserStory__StoryDetails", "object", "https://freetakteam.github.io/DAF/definition#ExternalClassifier_Story_0561D5D1"
    AddProperty "dUserStory", "TestScenario", "dUserStory__TestScenario", "literal", "string"
    AddProperty "dValue", "_Image", "dValue___Image", "literal", "string"
    AddProperty "dValue", "app_data_type", "dValue__app_data_type", "literal", "string"
    AddProperty "dValue", "column_name", "dValue__column_name", "literal", "string"
    AddProperty "dValue", "db_data_type", "dValue__db_data_type", "literal", "string"
    AddProperty "dValue", "display_type", "dValue__display_type", "literal", "string"
    AddProperty "dValue", "Icon", "dValue__Icon", "literal", "string"
    AddProperty "dValue", "input_type", "dValue__input_type", "literal", "string"
    AddProperty "dValue", "is_editable", "dValue__is_editable", "literal", "boolean"
    AddProperty "dValue", "restrictions_description", "dValue__restrictions_description", "literal", "string"
    AddProperty "dValue", "restrictions_match", "dValue__restrictions_match", "literal", "string"
    AddProperty "dValue", "restrictions_not_match", "dValue__restrictions_not_match", "literal", "string"
    AddProperty "dValueRef", "_Image", "dValueRef___Image", "literal", "string"
    AddProperty "dValueRef", "Icon", "dValueRef__Icon", "literal", "string"
    AddProperty "dValueRef", "reference_value", "dValueRef__reference_value", "object", "https://freetakteam.github.io/DAF/model#dValue"
    AddProperty "dValueStream", "Criticality", "dValueStream__Criticality", "literal", "string"
    AddProperty "dValueStream", "entrance criteria", "dValueStream__entrance_criteria", "literal", "int"
    AddProperty "dValueStream", "exit criteria", "dValueStream__exit_criteria", "literal", "int"
    AddProperty "dValueStream", "is Decomposed", "dValueStream__is_Decomposed", "literal", "boolean"
    AddProperty "dVolume", "MounthPath", "dVolume__MounthPath", "literal", "string"
    AddProperty "dVolume", "name", "dVolume__name", "literal", "string"
    AddProperty "dVolume", "subPath", "dVolume__subPath", "literal", "string"

    AddRelationship "dAccord", "dAccord", "dAccord_inverse", "dOpinion", "dOpinion"
    AddRelationship "dActionKey", "dActionKey", "dActionKey_inverse", "dController", "dController"
    AddRelationship "dActivityContainsAction", "dActivityContainsAction", "dActivityContainsAction_inverse", "dActivity", "dAction"
    AddRelationship "dActorParticipatesInBizUseCase", "dActorParticipatesInBizUseCase", "dActorParticipatesInBizUseCase_inverse", "dActor", "dBusinessUseCase"
    AddRelationship "dAPIAggregatesSchema", "dAPIAggregatesSchema", "dAPIAggregatesSchema_inverse", "dAPI", "dJSON_Schema"
    AddRelationship "dApplicationAgregatesFunction", "dApplicationAgregatesFunction", "dApplicationAgregatesFunction_inverse", "dApplicationComponent", "dApplicationFunction"
    AddRelationship "dApplicationComponentHasContainer", "dApplicationComponentHasContainer", "dApplicationComponentHasContainer_inverse", "dApplicationComponent", "dContainer"
    AddRelationship "dApplicationComponentRealizesogicalComponent", "dApplicationComponentRealizesogicalComponent", "dApplicationComponentRealizesogicalComponent_inverse", "dApplicationComponent", "dLogicalAppComponent"
    AddRelationship "dApplicationconfiguredbySystemConfiguration", "dApplicationconfiguredbySystemConfiguration", "dApplicationconfiguredbySystemConfiguration_inverse", "dApplicationComponent", "dSystem"
    AddRelationship "dApplicationConnectedWithApplication", "dApplicationConnectedWithApplication", "dApplicationConnectedWithApplication_inverse", "dApplicationComponent", "dApplicationComponent"
    AddRelationship "dApplicationExposesService", "dApplicationExposesService", "dApplicationExposesService_inverse", "dApplicationComponent", "dPhysicalService"
    AddRelationship "dApplicationHasOwner", "dApplicationHasOwner", "dApplicationHasOwner_inverse", "dApplicationComponent", "dStakeholder"
    AddRelationship "dApplicationIRunsInNode", "dApplicationIRunsInNode", "dApplicationIRunsInNode_inverse", "dDeploymentNode", "dApplicationComponent"
    AddRelationship "dApplicationRisk", "dApplicationRisk", "dApplicationRisk_inverse", "dRisk", "dApplicationComponent"
    AddRelationship "dAreaAggregatesCategories", "dAreaAggregatesCategories", "dAreaAggregatesCategories_inverse", "dMeasurementArea", "dMeasurementCategory"
    AddRelationship "dBizServIsDescribedByUseCase", "dBizServIsDescribedByUseCase", "dBizServIsDescribedByUseCase_inverse", "dBusinessUseCase", "dBusinessService"
    AddRelationship "dBizServUsesDataEntity", "dBizServUsesDataEntity", "dBizServUsesDataEntity_inverse", "dBusinessService", "dDataEntity"
    AddRelationship "dBusinessAreadHasCapability", "dBusinessAreadHasCapability", "dBusinessAreadHasCapability_inverse", "dBusinessArea", "dCapability"
    AddRelationship "dCapabilityisMeasuredByKPI", "dCapabilityisMeasuredByKPI", "dCapabilityisMeasuredByKPI_inverse", "dCapability", "dMeasurementIndicator"
    AddRelationship "dCategoryaggregatesGroups", "dCategoryaggregatesGroups", "dCategoryaggregatesGroups_inverse", "dMeasurementCategory", "dMeasurementGrouping"
    AddRelationship "dClusterContainsDeploymentNode", "dClusterContainsDeploymentNode", "dClusterContainsDeploymentNode_inverse", "dCluster", "dDeploymentNode"
    AddRelationship "dContainerAggregatesVolume", "dContainerAggregatesVolume", "dContainerAggregatesVolume_inverse", "dContainer", "dVolume"
    AddRelationship "dControllerControllsModel", "dControllerControllsModel", "dControllerControllsModel_inverse", "dController", "dModelClass"
    AddRelationship "dControllerGovernsView", "dControllerGovernsView", "dControllerGovernsView_inverse", "dController", "dView"
    AddRelationship "dControllerImplementsFunction", "dControllerImplementsFunction", "dControllerImplementsFunction_inverse", "dController", "dApplicationFunction"
    AddRelationship "dDataEntityInformsCapability", "dDataEntityInformsCapability", "dDataEntityInformsCapability_inverse", "dCapability", "dDataEntity"
    AddRelationship "dDecisionRefersToPrinciple", "dDecisionRefersToPrinciple", "dDecisionRefersToPrinciple_inverse", "dDecision", "dPrinciple"
    AddRelationship "dDeploymentModelAggregatesCluster", "dDeploymentModelAggregatesCluster", "dDeploymentModelAggregatesCluster_inverse", "dDeploymentModel", "dCluster"
    AddRelationship "dDiscord", "dDiscord", "dDiscord_inverse", "dOpinion", "dOpinion"
    AddRelationship "dEntityAssociatesEntity", "dEntityAssociatesEntity", "dEntityAssociatesEntity_inverse", "dDataEntity", "dDataEntity"
    AddRelationship "dEventTriggersProcess", "dEventTriggersProcess", "dEventTriggersProcess_inverse", "dEvent", "dBusinessProcess"
    AddRelationship "dFeatureIsRealizedByUseCase", "dFeatureIsRealizedByUseCase", "dFeatureIsRealizedByUseCase_inverse", "dBusinessUseCase", "dFeature"
    AddRelationship "dGoalAggregatesGoal", "dGoalAggregatesGoal", "dGoalAggregatesGoal_inverse", "dGoal", "dGoal"
    AddRelationship "dGoalhasObjective", "dGoalhasObjective", "dGoalhasObjective_inverse", "dGoal", "dObjective"
    AddRelationship "dGoalisOperationalizedByCapability", "dGoalisOperationalizedByCapability", "dGoalisOperationalizedByCapability_inverse", "dCapability", "dGoal"
    AddRelationship "dGroupAggregatesKPI", "dGroupAggregatesKPI", "dGroupAggregatesKPI_inverse", "dMeasurementGrouping", "dMeasurementIndicator"
    AddRelationship "dInitiativeIncreasesMaturityOf", "dInitiativeIncreasesMaturityOf", "dInitiativeIncreasesMaturityOf_inverse", "dInitiative", "dCapability"
    AddRelationship "dInitiativeisMakingUseOfDecision", "dInitiativeisMakingUseOfDecision", "dInitiativeisMakingUseOfDecision_inverse", "dDecision", "dInitiative"
    AddRelationship "dIssueStopsRealizationOfRequirement", "dIssueStopsRealizationOfRequirement", "dIssueStopsRealizationOfRequirement_inverse", "dIssue", "dRequirement"
    AddRelationship "dJSON_SchemaSubSetGeneralizes_JSON_Schema", "dJSON_SchemaSubSetGeneralizes_JSON_Schema", "dJSON_SchemaSubSetGeneralizes_JSON_Schema_inverse", "dJSON_Schema", "dJSON_SchemaSubSet"
    AddRelationship "dJSONElement_associates_JSONElement", "dJSONElement_associates_JSONElement", "dJSONElement_associates_JSONElement_inverse", "dJSON_Element", "dJSON_Element"
    AddRelationship "dJSONSchemaRealizesModel", "dJSONSchemaRealizesModel", "dJSONSchemaRealizesModel_inverse", "dJSON_Schema", "dModelClass"
    AddRelationship "dLocationHostsNode", "dLocationHostsNode", "dLocationHostsNode_inverse", "dLocation", "dDeploymentNode"
    AddRelationship "dLogAppCompExposesBizService", "dLogAppCompExposesBizService", "dLogAppCompExposesBizService_inverse", "dLogicalAppComponent", "dBusinessService"
    AddRelationship "dLogicalApplicationComponentSupportsCapability", "dLogicalApplicationComponentSupportsCapability", "dLogicalApplicationComponentSupportsCapability_inverse", "dCapability", "dLogicalAppComponent"
    AddRelationship "dModelClassAssociatesModelClass", "dModelClassAssociatesModelClass", "dModelClassAssociatesModelClass_inverse", "dModelClass", "dModelClass"
    AddRelationship "dModelClassRealizesEntity", "dModelClassRealizesEntity", "dModelClassRealizesEntity_inverse", "dModelClass", "dDataEntity"
    AddRelationship "dNetworkAggregatesSubNetwork", "dNetworkAggregatesSubNetwork", "dNetworkAggregatesSubNetwork_inverse", "dNetwork", "dSubNetwork"
    AddRelationship "dNetworkContainsNode", "dNetworkContainsNode", "dNetworkContainsNode_inverse", "dNetwork", "dDeploymentNode"
    AddRelationship "dNetworkHasSecurityGroup", "dNetworkHasSecurityGroup", "dNetworkHasSecurityGroup_inverse", "dNetwork", "dSecurityGroup"
    AddRelationship "dObjectInstanceofController", "dObjectInstanceofController", "dObjectInstanceofController_inverse", "dObject", "dController"
    AddRelationship "dObjectInstanceofModel", "dObjectInstanceofModel", "dObjectInstanceofModel_inverse", "dObject", "dModelClass"
    AddRelationship "dObjectInstanceofView", "dObjectInstanceofView", "dObjectInstanceofView_inverse", "dObject", "dView"
    AddRelationship "dOrgUnitHasStakeholders", "dOrgUnitHasStakeholders", "dOrgUnitHasStakeholders_inverse", "dOrganizationUnit", "dStakeholder"
    AddRelationship "dPackageIsDeliveredByInitiative", "dPackageIsDeliveredByInitiative", "dPackageIsDeliveredByInitiative_inverse", "dGrowthPackage", "dInitiative"
    AddRelationship "dPhysicalServiceImplementsBusinessService", "dPhysicalServiceImplementsBusinessService", "dPhysicalServiceImplementsBusinessService_inverse", "dPhysicalService", "dBusinessService"
    AddRelationship "dPolymorphicCollection", "dPolymorphicCollection", "dPolymorphicCollection_inverse", "dJSON_Schema", "dJSON_Schema"
    AddRelationship "dProcessEnsureCorrectOperationOfCapability", "dProcessEnsureCorrectOperationOfCapability", "dProcessEnsureCorrectOperationOfCapability_inverse", "dCapability", "dBusinessProcess"
    AddRelationship "dProcessFlowsToProcess", "dProcessFlowsToProcess", "dProcessFlowsToProcess_inverse", "dBusinessProcess", "dBusinessProcess"
    AddRelationship "dProcessOrchestratesService", "dProcessOrchestratesService", "dProcessOrchestratesService_inverse", "dBusinessProcess", "dBusinessService"
    AddRelationship "dProductIncludesProcess", "dProductIncludesProcess", "dProductIncludesProcess_inverse", "dProduct", "dBusinessProcess"
    AddRelationship "dProgramIsOrganizedInPackages", "dProgramIsOrganizedInPackages", "dProgramIsOrganizedInPackages_inverse", "dProgram", "dGrowthPackage"
    AddRelationship "dRegionAggregatesCluster", "dRegionAggregatesCluster", "dRegionAggregatesCluster_inverse", "dRegion", "dCluster"
    AddRelationship "dRelatedService", "dRelatedService", "dRelatedService_inverse", "dBusinessService", "dBusinessService"
    AddRelationship "dRequirementContainsRequirement", "dRequirementContainsRequirement", "dRequirementContainsRequirement_inverse", "dRequirement", "dRequirement"
    AddRelationship "dRequirementIsRelatedToGoal", "dRequirementIsRelatedToGoal", "dRequirementIsRelatedToGoal_inverse", "dRequirement", "dGoal"
    AddRelationship "dRequirementIsSatisfiedByFeature", "dRequirementIsSatisfiedByFeature", "dRequirementIsSatisfiedByFeature_inverse", "dFeature", "dRequirement"
    AddRelationship "dResourceimpactedByRisk", "dResourceimpactedByRisk", "dResourceimpactedByRisk_inverse", "dRisk", "dResource"
    AddRelationship "dResourceSupportsCapability", "dResourceSupportsCapability", "dResourceSupportsCapability_inverse", "dResource", "dCapability"
    AddRelationship "dRiskIRelatedToRisk", "dRiskIRelatedToRisk", "dRiskIRelatedToRisk_inverse", "dRisk", "dRisk"
    AddRelationship "dRiskRealizedByIssue", "dRiskRealizedByIssue", "dRiskRealizedByIssue_inverse", "dIssue", "dRisk"
    AddRelationship "dRoleConsumesService", "dRoleConsumesService", "dRoleConsumesService_inverse", "dRole", "dBusinessService"
    AddRelationship "dRoleExecutesCapability", "dRoleExecutesCapability", "dRoleExecutesCapability_inverse", "dCapability", "dRole"
    AddRelationship "dRoleHasSkill", "dRoleHasSkill", "dRoleHasSkill_inverse", "dRole", "dSkill"
    AddRelationship "dRoleisAssociatedToOrganization", "dRoleisAssociatedToOrganization", "dRoleisAssociatedToOrganization_inverse", "dRole", "dOrganizationUnit"
    AddRelationship "dRoleIsPerformedByActor", "dRoleIsPerformedByActor", "dRoleIsPerformedByActor_inverse", "dActor", "dRole"
    AddRelationship "dSchema_Associates_Schema", "dSchema_Associates_Schema", "dSchema_Associates_Schema_inverse", "dJSON_Schema", "dJSON_Schema"
    AddRelationship "dSchemaAssociatesElement", "dSchemaAssociatesElement", "dSchemaAssociatesElement_inverse", "dJSON_Schema", "dJSON_Element"
    AddRelationship "dSchemaGeneralizesSchema", "dSchemaGeneralizesSchema", "dSchemaGeneralizesSchema_inverse", "dJSON_Schema", "dJSON_Schema"
    AddRelationship "dSecurityGroupHasPhysicalService", "dSecurityGroupHasPhysicalService", "dSecurityGroupHasPhysicalService_inverse", "dSecurityGroup", "dPhysicalService"
    AddRelationship "dServiceRealizedByAPI", "dServiceRealizedByAPI", "dServiceRealizedByAPI_inverse", "dAPI", "dPhysicalService"
    AddRelationship "dStakeholderHasInnerOpinion", "dStakeholderHasInnerOpinion", "dStakeholderHasInnerOpinion_inverse", "dStakeholder", "dOpinionInner"
    AddRelationship "dStakeholderHasOpinion", "dStakeholderHasOpinion", "dStakeholderHasOpinion_inverse", "dStakeholder", "dOpinion"
    AddRelationship "dSubNetworkAggregatesIPRange", "dSubNetworkAggregatesIPRange", "dSubNetworkAggregatesIPRange_inverse", "dSubNetwork", "dIPRange"
    AddRelationship "dTableProvidesPersistenceForModelClass", "dTableProvidesPersistenceForModelClass", "dTableProvidesPersistenceForModelClass_inverse", "dModelClass", "dTable"
    AddRelationship "dTest_ApplicationComponent", "dTest_ApplicationComponent", "dTest_ApplicationComponent_inverse", "dTest", "dApplicationComponent"
    AddRelationship "dUseCaseContainsActivities", "dUseCaseContainsActivities", "dUseCaseContainsActivities_inverse", "dBusinessUseCase", "dActivity"
    AddRelationship "dUseCaseHasStory", "dUseCaseHasStory", "dUseCaseHasStory_inverse", "dUserStory", "dBusinessUseCase"
    AddRelationship "dUseCaseisImplementedByController", "dUseCaseisImplementedByController", "dUseCaseisImplementedByController_inverse", "dController", "dBusinessUseCase"
    AddRelationship "dValueStreamEnablesCapability", "dValueStreamEnablesCapability", "dValueStreamEnablesCapability_inverse", "dValueStream", "dCapability"
    AddRelationship "dValueStreamIncludesProcesses", "dValueStreamIncludesProcesses", "dValueStreamIncludesProcesses_inverse", "dValueStream", "dBusinessProcess"
    AddRelationship "dZoneAggregatesRegion", "dZoneAggregatesRegion", "dZoneAggregatesRegion_inverse", "dZone", "dRegion"

    ' Current M2 generalizations used for endpoint compatibility.
    AddGeneralization "dOnPremise", "dCluster"
    AddGeneralization "dPublicCluster", "dCluster"
    AddGeneralization "dValueRef", "dValue"

    ' -----------------------------------------------------------------------
    ' Confirmed DAF 6.3 migrations for historical EuroCOM stereotypes.
    ' These are semantic transformations, not guesses.
    ' -----------------------------------------------------------------------
    AddLegacyElementMigration "dWorkerInternal", "dActor", _
        "dActor__ActorType|string|Internal Worker"
    AddLegacyElementMigration "dWorkerExternal", "dActor", _
        "dActor__ActorType|string|External Worker"
    AddLegacyElementMigration "dWorker", "dActor", _
        "dActor__ActorType|string|Worker"
    AddLegacyElementMigration "dBusinessPartnerActive", "dActor", _
        "dActor__ActorType|string|Active Business Partner"
    AddLegacyElementMigration "dBusinessPartnerPassive", "dActor", _
        "dActor__ActorType|string|Passive Business Partner"
    AddLegacyElementMigration "dBusinessUseCaseCore", "dBusinessUseCase", _
        "dBusinessUseCase__isCore|boolean|true"
    AddLegacyElementMigration "dLogicalApplicationComponent", "dLogicalAppComponent", ""

    ' Confirmed legacy property renames already migrated in current DAF 6.3 M3.
    AddLegacyPropertyAlias "dRole", "areSkillsAvailable", "isSkillsAvailable"
    AddLegacyPropertyAlias "dRole", "areSkillsDefined", "isSkillsDefined"
    AddLegacyPropertyAlias "dLogicalAppComponent", "meetsBizNeeds", "isMeetingBusinessNeeds"
    AddLegacyPropertyAlias "dLogicalAppComponent", "meetsTomorrowNeeds", "isMeetingFutureNeeds"

    ' -----------------------------------------------------------------------
    ' Non-destructive external semantic mapping candidates.
    '
    ' These rules DO NOT change the source external object's RDF type.
    ' They emit separate dafi:SemanticMapping resources for later acceptance,
    ' transformation or rejection by the DAF runtime.
    ' -----------------------------------------------------------------------
    ' Trusted DAF ancestor/sibling profiles: transformations are applied.
    AddExternalMappingRule "BIZBOK::Capability", "dCapability", "applied", "exact", "trusted BIZBOK -> DAF mapping"
    AddExternalMappingRule "TOGAF::LogicalApplicationComponent", "dLogicalAppComponent", "applied", "exact", "trusted TOGAF -> DAF mapping"
    AddExternalMappingRule "TOGAF::SBB", "dApplicationComponent", "applied", "high", "trusted TOGAF SBB -> DAF application component"
    AddExternalMappingRule "Chronos::ChiNode", "dModelClass", "applied", "exact", "trusted Chronos -> DAF mapping"
    AddExternalMappingRule "Chronos::ChiRequirement", "dRequirement", "applied", "exact", "trusted Chronos -> DAF mapping"
    AddExternalMappingRule "TMF::TMF_JSON_Schema", "dJSON_Schema", "applied", "exact", "trusted TMF -> DAF mapping"

    ' Unqualified / other-profile equivalents remain candidates.
    AddExternalMappingRule "Capability", "dCapability", "candidate", "high", "source stereotype/metatype"
    AddExternalMappingRule "LogicalApplicationComponent", "dLogicalAppComponent", "candidate", "high", "source stereotype/metatype"
    AddExternalMappingRule "TMF_JSON_Schema", "dJSON_Schema", "candidate", "high", "source stereotype"
    AddExternalMappingRule "JSON Schema", "dJSON_Schema", "candidate", "high", "source metatype"
    AddExternalMappingRule "table", "dTable", "candidate", "high", "source stereotype"
    AddExternalMappingRule "ChiRequirement", "dRequirement", "candidate", "high", "source stereotype"
    AddExternalMappingRule "ArchitecturalDecision", "dDecision", "candidate", "high", "source stereotype"
    AddExternalMappingRule "DataObject", "dDataEntity", "candidate", "medium", "source stereotype/metatype"
    AddExternalMappingRule "ChiNode", "dModelClass", "candidate", "medium", "source stereotype"

    ' Explicit trusted relationship transformations.
    AddExternalRelationshipRule "TMF::TMF_APIAggregatesSchema", "dAPIAggregatesSchema", "exact", "trusted TMF relationship"
    AddExternalRelationshipRule "TOGAF::Supports", "dApplicationComponentRealizesogicalComponent", "high", "trusted TOGAF relationship"
End Sub

Sub AddClass(name)
    If Not classMap.Exists(name) Then classMap.Add name, True
End Sub

Sub AddProperty(className, tagName, predicateLocal, kind, targetType)
    Dim key
    key = className & "|" & tagName
    If Not propertyMap.Exists(key) Then
        propertyMap.Add key, predicateLocal & "|" & kind & "|" & targetType
    End If
End Sub

Sub AddRelationship(name, predicateLocal, inverseLocal, sourceClass, targetClass)
    If Not relationshipMap.Exists(name) Then relationshipMap.Add name, predicateLocal & "|" & inverseLocal
    If Not relationshipSourceMap.Exists(name) Then relationshipSourceMap.Add name, sourceClass
    If Not relationshipTargetMap.Exists(name) Then relationshipTargetMap.Add name, targetClass
    AddRelationshipPairCandidate sourceClass, targetClass, name
End Sub

Sub AddRelationshipPairCandidate(sourceClass, targetClass, relationshipName)
    Dim key
    key = LCase(Trim(CStr(sourceClass))) & "|" & LCase(Trim(CStr(targetClass)))

    If relationshipPairMap.Exists(key) Then
        relationshipPairMap(key) = relationshipPairMap(key) & vbTab & relationshipName
    Else
        relationshipPairMap.Add key, relationshipName
    End If
End Sub

Sub AddGeneralization(childClass, parentClass)
    If Not classParentMap.Exists(childClass) Then classParentMap.Add childClass, parentClass
End Sub

Sub AddLegacyElementMigration(sourceStereo, targetClass, injectedPropertyDefinition)
    If Not legacyElementTypeMap.Exists(sourceStereo) Then
        legacyElementTypeMap.Add sourceStereo, targetClass
    End If

    If Trim(CStr(injectedPropertyDefinition)) <> "" Then
        legacyElementInjectedPropertyMap.Add sourceStereo, injectedPropertyDefinition
    End If
End Sub

Sub AddLegacyPropertyAlias(className, legacyPropertyName, currentPropertyName)
    Dim key
    key = className & "|" & legacyPropertyName
    If Not legacyPropertyAliasMap.Exists(key) Then
        legacyPropertyAliasMap.Add key, currentPropertyName
    End If
End Sub

Sub AddExternalMappingRule(sourceKey, targetClass, mappingStatus, confidence, basis)
    If Not externalMappingRuleMap.Exists(sourceKey) Then
        externalMappingRuleMap.Add sourceKey, targetClass & "|" & mappingStatus & "|" & confidence & "|" & basis
    End If
End Sub

Sub AddExternalRelationshipRule(sourceKey, targetRelationship, confidence, basis)
    If Not externalRelationshipRuleMap.Exists(sourceKey) Then
        externalRelationshipRuleMap.Add sourceKey, targetRelationship & "|" & confidence & "|" & basis
    End If
End Sub

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

Sub WriteHeader()
    W "@prefix daf:      <https://freetakteam.github.io/DAF/model#> ."
    W "@prefix dafm:     <https://freetakteam.github.io/DAF/metamodel#> ."
    W "@prefix dafp:     <https://freetakteam.github.io/DAF/property#> ."
    W "@prefix dafrel:   <https://freetakteam.github.io/DAF/relationship#> ."
    W "@prefix dafpred:  <https://freetakteam.github.io/DAF/predicate#> ."
    W "@prefix dafi:     <https://freetakteam.github.io/DAF/instance#> ."
    W "@prefix m:        <" & modelPrefixBase & "> ."
    W "@prefix rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ."
    W "@prefix rdfs:     <http://www.w3.org/2000/01/rdf-schema#> ."
    W "@prefix owl:      <http://www.w3.org/2002/07/owl#> ."
    W "@prefix xsd:      <http://www.w3.org/2001/XMLSchema#> ."
    W "@prefix dcterms:  <http://purl.org/dc/terms/> ."
    W ""

    W "# Small M1 export vocabulary. This describes repository/package concerns"
    W "# that are intentionally separate from the DAF M2 semantic metamodel."
    W "dafi:DAFModel a rdfs:Class ; rdfs:label ""DAF model"" ."
    W "dafi:Package a rdfs:Class ; rdfs:label ""Model package"" ."
    W "dafi:GenericConnector a rdfs:Class ; rdfs:label ""Generic/unresolved connector"" ."
    W "dafi:ExternalElement a rdfs:Class ; rdfs:label ""First-level element outside selected export scope"" ."
    W "dafi:ExternalEndpoint a rdfs:Class ; rdfs:subClassOf dafi:ExternalElement ; rdfs:label ""External relationship endpoint"" ."
    W "dafi:ExternalRelationship a rdfs:Class ; rdfs:label ""Relationship crossing the selected DAF model boundary"" ."
    W "dafi:SemanticMapping a rdfs:Class ; rdfs:label ""Non-destructive semantic interpretation of a source resource"" ."
    W "dafi:rootPackage a rdf:Property ."
    W "dafi:parentPackage a rdf:Property ."
    W "dafi:containedInPackage a rdf:Property ."
    W "dafi:parentElement a rdf:Property ."
    W "dafi:dafVersion a rdf:Property ."
    W "dafi:metamodelExportVersion a rdf:Property ."
    W "dafi:exporterVersion a rdf:Property ."
    W "dafi:sourceElementType a rdf:Property ."
    W "dafi:sourceConnectorType a rdf:Property ."
    W "dafi:sourceConnectorName a rdf:Property ."
    W "dafi:sourceDirection a rdf:Property ."
    W "dafi:sourceClientRole a rdf:Property ."
    W "dafi:sourceSupplierRole a rdf:Property ."
    W "dafi:unresolvedDAFType a rdf:Property ."
    W "dafi:normalizedFromLegacyType a rdf:Property ."
    W "dafi:resolvedDAFType a rdf:Property ."
    W "dafi:relationshipResolution a rdf:Property ."
    W "dafi:semanticDirectionReversed a rdf:Property ."
    W "dafi:externalToExport a rdf:Property ."
    W "dafi:importDepth a rdf:Property ."
    W "dafi:sourceProfile a rdf:Property ."
    W "dafi:sourceMetaType a rdf:Property ."
    W "dafi:sourceAlias a rdf:Property ."
    W "dafi:sourceStatus a rdf:Property ."
    W "dafi:sourceVersion a rdf:Property ."
    W "dafi:sourceAuthor a rdf:Property ."
    W "dafi:sourcePackageName a rdf:Property ."
    W "dafi:sourcePackageGuid a rdf:Property ."
    W "dafi:sourceClassifierId a rdf:Property ."
    W "dafi:sourceClassifierGuid a rdf:Property ."
    W "dafi:sourceClassifierName a rdf:Property ."
    W "dafi:sourceFQName a rdf:Property ."
    W "dafi:sourceFQStereotype a rdf:Property ."
    W "dafi:sourceConnectorMetaType a rdf:Property ."
    W "dafi:sourceConnectorFQStereotype a rdf:Property ."
    W "dafi:sourceConnectorProfile a rdf:Property ."
    W "dafi:hasSemanticMapping a rdf:Property ."
    W "dafi:sourceResource a rdf:Property ."
    W "dafi:targetDAFType a rdf:Property ."
    W "dafi:targetDAFRelationshipType a rdf:Property ."
    W "dafi:mappingRule a rdf:Property ."
    W "dafi:mappingStatus a rdf:Property ."
    W "dafi:mappingConfidence a rdf:Property ."
    W "dafi:mappingBasis a rdf:Property ."
    W "dafi:mappingDirectionReversed a rdf:Property ."
    W "dafi:transformationApplied a rdf:Property ."
    W "dafi:transformedFromProfile a rdf:Property ."
    W ""

    W "m:model"
    W "    a dafi:DAFModel ;"
    W "    dcterms:title " & Lit(rootPackage.Name) & " ;"
    W "    dafi:dafVersion " & Lit(DAF_VERSION) & " ;"
    W "    dafi:metamodelExportVersion " & Lit(METAMODEL_EXPORT_VERSION) & " ;"
    W "    dafi:exporterVersion " & Lit(EXPORTER_VERSION) & " ;"
    W "    dcterms:created " & TypedLit(IsoDateTime(Now), "dateTime") & " ;"
    W "    dafi:rootPackage " & PackageIri(rootPackage.PackageID) & " ."
    W ""

    Report "DAF M1 RDF MODEL EXPORT REPORT"
    Report "Generated: " & Now
    Report "Exporter version: " & EXPORTER_VERSION
    Report "DAF framework version: " & DAF_VERSION
    Report "Semantic metamodel export contract: " & METAMODEL_EXPORT_VERSION
    Report "Root package: " & rootPackage.Name
    Report "Root package GUID: " & rootPackage.PackageGUID
    Report "Output: " & outputFile
    Report ""
End Sub

Sub CollectPackage(pkg)
    Dim pIri
    pIri = ResourceIri("package", pkg.PackageGUID)
    If Not packageIriById.Exists(CStr(pkg.PackageID)) Then
        packageIriById.Add CStr(pkg.PackageID), pIri
        packageCount = packageCount + 1
    End If

    Dim el
    For Each el In pkg.Elements
        CollectElementRecursive el, pIri, ""
    Next

    Dim childPkg
    For Each childPkg In pkg.Packages
        CollectPackage childPkg
    Next
End Sub

Sub CollectElementRecursive(el, packageIri, parentDafElementIri)
    Dim sourceStereo, dafStereo
    sourceStereo = FindDAFElementStereotype(el)
    dafStereo = NormalizeDAFElementType(sourceStereo)

    Dim nextParent
    nextParent = parentDafElementIri

    If sourceStereo <> "" Then
        Dim eIri, normGuid
        eIri = ResourceIri("element", el.ElementGUID)
        normGuid = NormalizeGuid(el.ElementGUID)

        If Not elementIriById.Exists(CStr(el.ElementID)) Then
            elementIriById.Add CStr(el.ElementID), eIri
            elementIriByGuid.Add normGuid, eIri
            elementStereoById.Add CStr(el.ElementID), dafStereo
            elementSourceStereoById.Add CStr(el.ElementID), sourceStereo
            elementCount = elementCount + 1
        End If

        nextParent = eIri

        If sourceStereo <> dafStereo Then
            IncrementCount legacyElementMigrationCounts, sourceStereo & " -> " & dafStereo
        ElseIf Not classMap.Exists(dafStereo) Then
            IncrementCount unknownElementTypeCounts, sourceStereo
        End If
    End If

    Dim child
    For Each child In el.Elements
        CollectElementRecursive child, packageIri, nextParent
    Next
End Sub

Sub WritePackageTree(pkg, parentPackageIri)
    Dim pIri
    pIri = PackageIri(pkg.PackageID)

    W "# Package: " & OneLine(pkg.Name)
    W pIri
    W "    a dafi:Package ;"
    W "    rdfs:label " & Lit(pkg.Name) & " ;"
    W "    dafm:eaGuid " & Lit(pkg.PackageGUID) & " ;"
    W "    dcterms:description " & Lit(pkg.Notes) & IIfSuffix(parentPackageIri <> "", " ;", " .")

    If parentPackageIri <> "" Then
        W "    dafi:parentPackage " & parentPackageIri & " ."
    End If
    W ""

    Dim childPkg
    For Each childPkg In pkg.Packages
        WritePackageTree childPkg, pIri
    Next
End Sub

Sub WritePackageElements(pkg)
    Dim pIri
    pIri = PackageIri(pkg.PackageID)

    Dim el
    For Each el In pkg.Elements
        WriteElementRecursive el, pIri, ""
    Next

    Dim childPkg
    For Each childPkg In pkg.Packages
        WritePackageElements childPkg
    Next

    ' Connectors are emitted after all elements in this package tree are known.
    For Each el In pkg.Elements
        WriteConnectorsRecursive el
    Next
End Sub

Sub WriteElementRecursive(el, packageIri, parentDafElementIri)
    Dim sourceStereo, dafStereo
    sourceStereo = FindDAFElementStereotype(el)
    dafStereo = NormalizeDAFElementType(sourceStereo)

    Dim nextParent
    nextParent = parentDafElementIri

    If sourceStereo <> "" Then
        Dim eIri
        eIri = ElementIri(el.ElementID)
        nextParent = eIri

        W "# Element: " & OneLine(el.Name) & " [" & sourceStereo & " -> " & dafStereo & "]"
        W eIri
        If classMap.Exists(dafStereo) Then
            W "    a daf:" & TurtleLocal(dafStereo) & " ;"
        Else
            W "    a dafm:ModelElement ;"
            W "    dafi:unresolvedDAFType " & Lit(sourceStereo) & " ;"
        End If

        W "    dafp:id " & TypedLit(NormalizeGuid(el.ElementGUID), "string") & " ;"
        W "    dafp:name " & Lit(el.Name) & " ;"
        W "    dafm:eaGuid " & Lit(el.ElementGUID) & " ;"
        W "    dafp:stereotype " & Lit(dafStereo) & " ;"
        W "    dafp:modelType " & Lit(el.Type) & " ;"
        W "    dafi:sourceElementType " & Lit(el.Type) & " ;"
        W "    dafi:containedInPackage " & packageIri & " ;"

        If sourceStereo <> dafStereo Then
            W "    dafi:normalizedFromLegacyType " & Lit(sourceStereo) & " ;"
        End If

        If parentDafElementIri <> "" Then
            W "    dafi:parentElement " & parentDafElementIri & " ;"
        End If

        WriteOptionalElementProperties el
        WriteLegacyElementInjectedProperties el, sourceStereo, dafStereo

        ' Preserve the actual EA source stereotype/profile information.
        W "    dafm:sourceStereotype " & Lit(el.StereotypeEx) & " ."
        W ""

        If Trim(CStr(el.Name)) = "" Then unnamedElementCount = unnamedElementCount + 1

        ExportElementTaggedValues el, eIri, dafStereo
    End If

    Dim child
    For Each child In el.Elements
        WriteElementRecursive child, packageIri, nextParent
    Next
End Sub

Sub WriteOptionalElementProperties(el)
    If Trim(CStr(el.Alias)) <> "" Then W "    dafp:alias " & Lit(el.Alias) & " ;"
    If Trim(CStr(el.Notes)) <> "" Then W "    dafp:notes " & Lit(el.Notes) & " ;"
    If Trim(CStr(el.Status)) <> "" Then W "    dafp:status " & Lit(el.Status) & " ;"
    If Trim(CStr(el.Version)) <> "" Then W "    dafp:version " & Lit(el.Version) & " ;"
    If Trim(CStr(el.Phase)) <> "" Then W "    dafp:phase " & Lit(el.Phase) & " ;"
    If Trim(CStr(el.Author)) <> "" Then W "    dafp:author " & Lit(el.Author) & " ;"
    If Trim(CStr(el.Visibility)) <> "" Then W "    dafp:visibility " & Lit(el.Visibility) & " ;"
    If Trim(CStr(el.Complexity)) <> "" Then W "    dafp:complexity " & Lit(el.Complexity) & " ;"

    If IsDate(el.Created) Then W "    dafp:createdAt " & TypedLit(IsoDateTime(el.Created), "dateTime") & " ;"
    If IsDate(el.Modified) Then W "    dafp:modifiedAt " & TypedLit(IsoDateTime(el.Modified), "dateTime") & " ;"
End Sub

Sub ExportElementTaggedValues(el, ownerIri, dafStereo)
    Dim i, tv, rawValue, tagIri
    i = 0

    For Each tv In el.TaggedValues
        i = i + 1
        rawValue = TaggedValueActualValue(tv)
        rawTaggedValueCount = rawTaggedValueCount + 1
        tagIri = ResourceIriWithSuffix("tag", el.ElementGUID, CStr(i))

        ' Lossless/raw provenance representation.
        W ownerIri & " dafm:hasTaggedValue " & tagIri & " ."
        W tagIri
        W "    a dafm:TaggedValue ;"
        W "    dafm:tagName " & Lit(tv.Name) & " ;"
        W "    dafm:tagValue " & Lit(rawValue) & " ;"
        W "    dafm:ownerKind ""element"" ."
        W ""

        If LCase(Trim(CStr(tv.Name))) = "id" Then
            suppressedIdTagCount = suppressedIdTagCount + 1
        Else
            ExportMappedPropertyValue ownerIri, dafStereo, tv.Name, rawValue
        End If
    Next
End Sub

Sub ExportMappedPropertyValue(ownerIri, dafStereo, tagName, rawValue)
    Dim key, effectiveTagName
    effectiveTagName = CStr(tagName)
    key = dafStereo & "|" & effectiveTagName

    If Not propertyMap.Exists(key) Then
        If legacyPropertyAliasMap.Exists(key) Then
            effectiveTagName = legacyPropertyAliasMap(key)
            IncrementCount legacyPropertyMigrationCounts, _
                dafStereo & "." & CStr(tagName) & " -> " & effectiveTagName
            key = dafStereo & "|" & effectiveTagName
        End If
    End If

    If Not propertyMap.Exists(key) Then
        IncrementCount unmappedTagCounts, dafStereo & "." & CStr(tagName)
        Exit Sub
    End If

    Dim parts, predicateLocal, kind, targetType
    parts = Split(propertyMap(key), "|")
    predicateLocal = parts(0)
    kind = parts(1)
    targetType = parts(2)

    If kind = "object" Then
        If EmitObjectProperty(ownerIri, predicateLocal, rawValue) Then
            mappedPropertyValueCount = mappedPropertyValueCount + 1
        Else
            unresolvedObjectReferenceCount = unresolvedObjectReferenceCount + 1
            IncrementCount invalidTypedValueCounts, dafStereo & "." & CStr(tagName) & " [unresolved object reference]"
        End If
    Else
        Dim semanticValue, lexical
        semanticValue = TransformLegacySemanticValue( _
            dafStereo, effectiveTagName, rawValue, targetType)
        lexical = SemanticLiteral(semanticValue, targetType)

        If lexical = "" Then
            ' Empty/invalid non-string semantic values are not projected.
            ' Their original EA tagged value has already been preserved above.
            If Trim(CStr(rawValue)) <> "" Then
                IncrementCount invalidTypedValueCounts, dafStereo & "." & CStr(tagName) & " [" & targetType & "]"
            End If
        Else
            W ownerIri & " dafp:" & TurtleLocal(predicateLocal) & " " & lexical & " ."
            W ""
            mappedPropertyValueCount = mappedPropertyValueCount + 1
        End If
    End If
End Sub

Function EmitObjectProperty(ownerIri, predicateLocal, rawValue)
    EmitObjectProperty = False

    Dim re, matches, m, guidValue, foundAny
    Set re = CreateObject("VBScript.RegExp")
    re.Global = True
    re.IgnoreCase = True
    re.Pattern = "\{?[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}?"

    Set matches = re.Execute(CStr(rawValue))
    foundAny = False

    For Each m In matches
        guidValue = NormalizeGuid(m.Value)
        If elementIriByGuid.Exists(guidValue) Then
            W ownerIri & " dafp:" & TurtleLocal(predicateLocal) & " " & elementIriByGuid(guidValue) & " ."
            foundAny = True
        End If
    Next

    EmitObjectProperty = foundAny
End Function

Sub WriteConnectorsRecursive(el)
    If elementIriById.Exists(CStr(el.ElementID)) Then
        Dim c
        For Each c In el.Connectors
            WriteConnector c
        Next
    End If

    Dim child
    For Each child In el.Elements
        WriteConnectorsRecursive child
    Next
End Sub

Sub WriteConnector(c)
    Dim cGuid
    cGuid = NormalizeGuid(c.ConnectorGUID)

    If exportedConnectorGuids.Exists(cGuid) Then Exit Sub
    exportedConnectorGuids.Add cGuid, True

    Dim clientIri, supplierIri
    clientIri = GetEndpointIri(c.ClientID)
    supplierIri = GetEndpointIri(c.SupplierID)

    If clientIri = "" Or supplierIri = "" Then
        ' Extremely defensive fallback: preserve count and report, but avoid
        ' generating an invalid connector with a missing RDF endpoint.
        IncrementCount unknownRelationshipTypeCounts, _
            "<endpoint unavailable> " & CStr(c.ConnectorGUID)
        Exit Sub
    End If

    Dim isExternalConnector
    isExternalConnector = False

    If Not elementIriById.Exists(CStr(c.ClientID)) _
        Or Not elementIriById.Exists(CStr(c.SupplierID)) Then
        externalConnectorCount = externalConnectorCount + 1
        externalRelationshipCount = externalRelationshipCount + 1
        isExternalConnector = True
    End If

    Dim clientType, supplierType
    clientType = GetEndpointSemanticType(c.ClientID)
    supplierType = GetEndpointSemanticType(c.SupplierID)

    Dim sourceStereo, resolvedRelationship, resolutionMode
    Dim semanticSourceIri, semanticTargetIri, reversedDirection
    sourceStereo = FindDAFRelationshipStereotype(c)
    resolvedRelationship = ""
    resolutionMode = "unresolved"
    semanticSourceIri = clientIri
    semanticTargetIri = supplierIri
    reversedDirection = False

    ResolveRelationshipSemantics sourceStereo, clientType, supplierType, _
        resolvedRelationship, resolutionMode, reversedDirection

    If resolvedRelationship <> "" Then
        If reversedDirection Then
            semanticSourceIri = supplierIri
            semanticTargetIri = clientIri
            relationshipDirectionReversedCount = relationshipDirectionReversedCount + 1
        End If
    End If

    Dim relIri
    relIri = ResourceIri("relationship", c.ConnectorGUID)
    relationshipCount = relationshipCount + 1

    W "# Relationship: " & OneLine(c.Name)
    W relIri

    If resolvedRelationship <> "" Then
        If isExternalConnector Then
            W "    a dafm:Relationship, dafi:ExternalRelationship, dafrel:" & TurtleLocal(resolvedRelationship) & " ;"
        Else
            W "    a dafm:Relationship, dafrel:" & TurtleLocal(resolvedRelationship) & " ;"
        End If
        W "    dafm:relationshipType dafrel:" & TurtleLocal(resolvedRelationship) & " ;"
        semanticRelationshipCount = semanticRelationshipCount + 1

        If resolutionMode = "exact-stereotype" Then
            relationshipResolvedExactCount = relationshipResolvedExactCount + 1
        ElseIf resolutionMode = "endpoint-types" Then
            relationshipResolvedByEndpointsCount = relationshipResolvedByEndpointsCount + 1
            If sourceStereo <> "" Then
                IncrementCount legacyRelationshipMigrationCounts, _
                    sourceStereo & " -> " & resolvedRelationship
            Else
                IncrementCount legacyRelationshipMigrationCounts, _
                    "<no stereotype> -> " & resolvedRelationship
            End If
        End If
    Else
        If isExternalConnector Then
            W "    a dafm:Relationship, dafi:ExternalRelationship, dafi:GenericConnector ;"
        Else
            W "    a dafm:Relationship, dafi:GenericConnector ;"
        End If
        genericConnectorCount = genericConnectorCount + 1

        If sourceStereo <> "" Then
            W "    dafi:unresolvedDAFType " & Lit(sourceStereo) & " ;"
            IncrementCount unknownRelationshipTypeCounts, sourceStereo
        End If
    End If

    W "    dafm:source " & semanticSourceIri & " ;"
    W "    dafm:target " & semanticTargetIri & " ;"
    W "    dafm:eaGuid " & Lit(c.ConnectorGUID) & " ;"
    W "    dafi:relationshipResolution " & Lit(resolutionMode) & " ;"
    W "    dafi:semanticDirectionReversed " & BooleanLiteral(reversedDirection) & " ;"
    W "    dafi:sourceConnectorType " & Lit(c.Type) & " ;"
    W "    dafi:sourceConnectorName " & Lit(c.Name) & " ;"
    W "    dafi:sourceDirection " & Lit(c.Direction) & " ;"
    W "    dafi:sourceClientRole " & Lit(c.ClientEnd.Role) & " ;"
    W "    dafi:sourceSupplierRole " & Lit(c.SupplierEnd.Role) & " ;"

    Dim connectorFQStereo, connectorProfile, connectorMetaType
    connectorFQStereo = SafeConnectorFQStereotype(c)
    connectorProfile = ExtractProfileName(connectorFQStereo)
    connectorMetaType = SafeConnectorMetaType(c)

    If connectorFQStereo <> "" Then
        W "    dafi:sourceConnectorFQStereotype " & Lit(connectorFQStereo) & " ;"
        If isExternalConnector Then externalConnectorFQStereotypeCount = externalConnectorFQStereotypeCount + 1
    End If

    If connectorProfile <> "" Then
        W "    dafi:sourceConnectorProfile " & Lit(connectorProfile) & " ;"
    End If

    If connectorMetaType <> "" Then
        W "    dafi:sourceConnectorMetaType " & Lit(connectorMetaType) & " ;"
    End If

    W "    dafm:sourceStereotype " & Lit(c.StereotypeEx) & " ."
    W ""

    If isExternalConnector Then
        IncrementCount externalRelationshipProfileCounts, ReportBucket(connectorProfile)
    End If

    ExportConnectorTaggedValues c, relIri

    If isExternalConnector And resolvedRelationship = "" Then
        WriteExternalRelationshipSemanticMapping c, relIri
    End If

    If resolvedRelationship <> "" Then
        Dim parts, forwardPred, inversePred
        parts = Split(relationshipMap(resolvedRelationship), "|")
        forwardPred = parts(0)
        inversePred = parts(1)

        W semanticSourceIri & " dafpred:" & TurtleLocal(forwardPred) & " " & semanticTargetIri & " ."
        projectionCount = projectionCount + 1

        If inversePred <> "" Then
            W semanticTargetIri & " dafpred:" & TurtleLocal(inversePred) & " " & semanticSourceIri & " ."
            projectionCount = projectionCount + 1
        End If
        W ""
    End If
End Sub

Sub WriteExternalRelationshipSemanticMapping(c, relationshipIri)
    Dim candidateClientType, candidateSupplierType
    Dim appliedClientType, appliedSupplierType
    Dim sourceProfileClient, sourceProfileSupplier
    Dim fqStereo, rawStereo

    candidateClientType = GetEndpointCandidateDAFType(c.ClientID)
    candidateSupplierType = GetEndpointCandidateDAFType(c.SupplierID)
    appliedClientType = GetEndpointAppliedDAFType(c.ClientID)
    appliedSupplierType = GetEndpointAppliedDAFType(c.SupplierID)
    sourceProfileClient = GetEndpointSourceProfile(c.ClientID)
    sourceProfileSupplier = GetEndpointSourceProfile(c.SupplierID)
    fqStereo = SafeConnectorFQStereotype(c)
    rawStereo = FirstStereotypeToken(c.StereotypeEx)

    Dim targetRelationship, mappingStatus, confidence, basis, ruleName, reversedDirection
    targetRelationship = ""
    mappingStatus = ""
    confidence = ""
    basis = ""
    ruleName = ""
    reversedDirection = False

    ' -----------------------------------------------------------------------
    ' 1. Explicit source-profile relationship rules.
    ' -----------------------------------------------------------------------
    Dim relRuleKey, relRuleParts
    relRuleKey = ""

    If fqStereo <> "" And externalRelationshipRuleMap.Exists(fqStereo) Then
        relRuleKey = fqStereo
    ElseIf rawStereo <> "" And externalRelationshipRuleMap.Exists(rawStereo) Then
        relRuleKey = rawStereo
    End If

    If relRuleKey <> "" Then
        relRuleParts = Split(externalRelationshipRuleMap(relRuleKey), "|")
        targetRelationship = relRuleParts(0)
        confidence = relRuleParts(1)
        basis = relRuleParts(2)
        mappingStatus = "applied"
        ruleName = "trusted-" & SafeLocal(relRuleKey) & "-to-" & SafeLocal(targetRelationship)

        reversedDirection = RelationshipNeedsReverse( _
            appliedClientType, appliedSupplierType, targetRelationship)
    End If

    ' -----------------------------------------------------------------------
    ' 2. Chronos trusted relationship transformations where the connector is
    '    an ordinary UML connector without a Chronos FQStereotype.
    ' -----------------------------------------------------------------------
    If targetRelationship = "" Then
        If LCase(sourceProfileClient) = "chronos" Or LCase(sourceProfileSupplier) = "chronos" Then

            If LCase(Trim(CStr(c.Type))) = "association" _
                And LCase(appliedClientType) = "dmodelclass" _
                And LCase(appliedSupplierType) = "dmodelclass" Then

                targetRelationship = "dModelClassAssociatesModelClass"
                mappingStatus = "applied"
                confidence = "high"
                basis = "trusted Chronos model-class association"
                ruleName = "chronos-association-to-dModelClassAssociatesModelClass"
                reversedDirection = False

            ElseIf LCase(Trim(CStr(c.Type))) = "realisation" _
                And ((LCase(appliedClientType) = "dfeature" And LCase(appliedSupplierType) = "drequirement") _
                  Or (LCase(appliedClientType) = "drequirement" And LCase(appliedSupplierType) = "dfeature")) Then

                targetRelationship = "dRequirementIsSatisfiedByFeature"
                mappingStatus = "applied"
                confidence = "high"
                basis = "trusted Chronos requirement realized by DAF feature"
                ruleName = "chronos-realisation-to-dRequirementIsSatisfiedByFeature"
                reversedDirection = RelationshipNeedsReverse( _
                    appliedClientType, appliedSupplierType, targetRelationship)
            End If
        End If
    End If

    ' -----------------------------------------------------------------------
    ' 3. Structural candidate fallback. This never asserts semantic equivalence.
    ' -----------------------------------------------------------------------
    If targetRelationship = "" Then
        If candidateClientType = "" Or candidateSupplierType = "" Then
            RecordTrustedRelationshipWithoutEquivalent c, _
                sourceProfileClient, sourceProfileSupplier, _
                candidateClientType, candidateSupplierType
            Exit Sub
        End If

        Dim candidateCount, candidateName, candidateReversed
        candidateName = ""
        candidateReversed = False

        candidateCount = FindUniqueRelationshipForEndpoints( _
            candidateClientType, candidateSupplierType, candidateName, candidateReversed)

        If candidateCount = 1 And candidateName <> "" Then
            If IsSafeStructuralRelationshipCandidate(c, candidateName) Then
                targetRelationship = candidateName
                mappingStatus = "candidate"
                confidence = "structural"
                basis = candidateClientType & " <-> " & candidateSupplierType
                ruleName = "external-endpoint-types-to-m2-relationship"
                reversedDirection = candidateReversed
            End If
        End If
    End If

    If targetRelationship = "" Then
        RecordTrustedRelationshipWithoutEquivalent c, _
            sourceProfileClient, sourceProfileSupplier, _
            candidateClientType, candidateSupplierType
        Exit Sub
    End If

    Dim mapIri
    mapIri = ResourceIri("relationship_mapping", c.ConnectorGUID)

    W relationshipIri & " dafi:hasSemanticMapping " & mapIri & " ."
    W mapIri
    W "    a dafi:SemanticMapping ;"
    W "    dafi:sourceResource " & relationshipIri & " ;"
    W "    dafi:targetDAFRelationshipType dafrel:" & TurtleLocal(targetRelationship) & " ;"
    W "    dafi:mappingRule " & Lit(ruleName) & " ;"
    W "    dafi:mappingStatus " & Lit(mappingStatus) & " ;"
    W "    dafi:mappingConfidence " & Lit(confidence) & " ;"
    W "    dafi:mappingBasis " & Lit(basis) & " ;"
    W "    dafi:mappingDirectionReversed " & BooleanLiteral(reversedDirection) & " ."
    W ""

    externalRelationshipMappingCount = externalRelationshipMappingCount + 1
    IncrementCount externalRelationshipMappingCounts, _
        mappingStatus & ": " & ReportBucket(rawStereo) & " -> " & targetRelationship

    If mappingStatus = "applied" Then
        externalAppliedRelationshipTransformationCount = _
            externalAppliedRelationshipTransformationCount + 1

        IncrementCount trustedRelationshipTransformationCounts, _
            TrustedRelationshipProfileLabel(sourceProfileClient, sourceProfileSupplier) _
            & ": " & ReportBucket(rawStereo) & " -> " & targetRelationship

        WriteAppliedRelationshipProjection c, targetRelationship, reversedDirection
    Else
        externalCandidateRelationshipMappingCount = _
            externalCandidateRelationshipMappingCount + 1
    End If
End Sub

Function RelationshipNeedsReverse(clientType, supplierType, relationshipName)
    RelationshipNeedsReverse = False

    If Not relationshipSourceMap.Exists(relationshipName) _
        Or Not relationshipTargetMap.Exists(relationshipName) Then Exit Function

    Dim expectedSource, expectedTarget
    expectedSource = relationshipSourceMap(relationshipName)
    expectedTarget = relationshipTargetMap(relationshipName)

    If IsClassCompatible(clientType, expectedTarget) _
        And IsClassCompatible(supplierType, expectedSource) Then
        RelationshipNeedsReverse = True
    End If
End Function

Function IsSafeStructuralRelationshipCandidate(c, candidateName)
    IsSafeStructuralRelationshipCandidate = True

    Dim connectorType
    connectorType = LCase(Trim(CStr(c.Type)))

    ' A UML generalization is not equivalent to a DAF association merely
    ' because dModelClassAssociatesModelClass is the only self-pair relation.
    If connectorType = "generalization" Then
        If InStr(LCase(candidateName), "generaliz") = 0 Then
            IsSafeStructuralRelationshipCandidate = False
            Exit Function
        End If
    End If

    ' Generic association must not be coerced to containment.
    If connectorType = "association" Then
        If InStr(LCase(candidateName), "contain") > 0 _
            Or InStr(LCase(candidateName), "aggregate") > 0 Then
            IsSafeStructuralRelationshipCandidate = False
            Exit Function
        End If
    End If
End Function

Sub WriteAppliedRelationshipProjection(c, relationshipName, reversedDirection)
    If Not relationshipMap.Exists(relationshipName) Then Exit Sub

    Dim clientIri, supplierIri, semanticSourceIri, semanticTargetIri
    clientIri = GetEndpointIri(c.ClientID)
    supplierIri = GetEndpointIri(c.SupplierID)

    semanticSourceIri = clientIri
    semanticTargetIri = supplierIri

    If reversedDirection Then
        semanticSourceIri = supplierIri
        semanticTargetIri = clientIri
    End If

    Dim parts, forwardPred, inversePred
    parts = Split(relationshipMap(relationshipName), "|")
    forwardPred = parts(0)
    inversePred = parts(1)

    W "# Applied trusted external relationship projection: " & relationshipName
    W semanticSourceIri & " dafpred:" & TurtleLocal(forwardPred) & " " & semanticTargetIri & " ."

    If inversePred <> "" Then
        W semanticTargetIri & " dafpred:" & TurtleLocal(inversePred) & " " & semanticSourceIri & " ."
    End If
    W ""
End Sub

Sub RecordTrustedRelationshipWithoutEquivalent(c, clientProfile, supplierProfile, _
        candidateClientType, candidateSupplierType)

    Dim trustedProfile
    trustedProfile = ""

    If IsTrustedTransformationProfile(clientProfile) Then
        trustedProfile = clientProfile
    ElseIf IsTrustedTransformationProfile(supplierProfile) Then
        trustedProfile = supplierProfile
    End If

    If trustedProfile = "" Then Exit Sub

    IncrementCount trustedRelationshipNoEquivalentCounts, _
        trustedProfile & ": " & ReportBucket(c.Type) _
        & " / " & ReportBucket(FirstStereotypeToken(c.StereotypeEx)) _
        & " [" & ReportBucket(candidateClientType) _
        & " -> " & ReportBucket(candidateSupplierType) & "]"
End Sub

Function TrustedRelationshipProfileLabel(clientProfile, supplierProfile)
    If IsTrustedTransformationProfile(clientProfile) Then
        TrustedRelationshipProfileLabel = clientProfile
    ElseIf IsTrustedTransformationProfile(supplierProfile) Then
        TrustedRelationshipProfileLabel = supplierProfile
    Else
        TrustedRelationshipProfileLabel = "<other>"
    End If
End Function

Sub ResolveRelationshipSemantics(sourceStereo, clientType, supplierType, _
        ByRef relationshipName, ByRef resolutionMode, ByRef reversedDirection)

    relationshipName = ""
    resolutionMode = "unresolved"
    reversedDirection = False

    ' 1. Exact current DAF 6.3 relationship stereotype is authoritative when
    ' endpoint types are compatible in either semantic direction.
    If sourceStereo <> "" And relationshipMap.Exists(sourceStereo) Then
        Dim expectedSource, expectedTarget
        expectedSource = relationshipSourceMap(sourceStereo)
        expectedTarget = relationshipTargetMap(sourceStereo)

        If IsClassCompatible(clientType, expectedSource) _
            And IsClassCompatible(supplierType, expectedTarget) Then
            relationshipName = sourceStereo
            resolutionMode = "exact-stereotype"
            Exit Sub
        End If

        If IsClassCompatible(clientType, expectedTarget) _
            And IsClassCompatible(supplierType, expectedSource) Then
            relationshipName = sourceStereo
            resolutionMode = "exact-stereotype"
            reversedDirection = True
            Exit Sub
        End If

        IncrementCount relationshipEndpointMismatchCounts, sourceStereo _
            & " expected " & expectedSource & " -> " & expectedTarget _
            & "; found " & clientType & " -> " & supplierType
    End If

    ' 2. Legacy/untyped connector: derive the current RelationshipType only
    ' when the endpoint classes identify exactly one compatible M2 relation.
    Dim candidateCount, candidateName, candidateReversed
    candidateCount = FindUniqueRelationshipForEndpoints( _
        clientType, supplierType, candidateName, candidateReversed)

    If candidateCount = 1 Then
        relationshipName = candidateName
        resolutionMode = "endpoint-types"
        reversedDirection = candidateReversed
    ElseIf candidateCount > 1 Then
        ambiguousRelationshipCount = ambiguousRelationshipCount + 1
        IncrementCount ambiguousRelationshipCounts, _
            clientType & " <-> " & supplierType & " candidates=" & CStr(candidateCount)
        resolutionMode = "ambiguous-endpoint-types"
    End If
End Sub

Function FindUniqueRelationshipForEndpoints(clientType, supplierType, _
        ByRef relationshipName, ByRef reversedDirection)

    FindUniqueRelationshipForEndpoints = 0
    relationshipName = ""
    reversedDirection = False

    If Trim(CStr(clientType)) = "" Or Trim(CStr(supplierType)) = "" Then Exit Function

    Dim candidates, directions
    Set candidates = CreateObject("Scripting.Dictionary")
    candidates.CompareMode = 1
    Set directions = CreateObject("Scripting.Dictionary")
    directions.CompareMode = 1

    Dim relName, expectedSource, expectedTarget
    For Each relName In relationshipMap.Keys
        expectedSource = relationshipSourceMap(relName)
        expectedTarget = relationshipTargetMap(relName)

        If IsClassCompatible(clientType, expectedSource) _
            And IsClassCompatible(supplierType, expectedTarget) Then
            If Not candidates.Exists(relName) Then
                candidates.Add relName, True
                directions.Add relName, False
            End If
        End If

        If IsClassCompatible(clientType, expectedTarget) _
            And IsClassCompatible(supplierType, expectedSource) Then
            If Not candidates.Exists(relName) Then
                candidates.Add relName, True
                directions.Add relName, True
            End If
        End If
    Next

    FindUniqueRelationshipForEndpoints = candidates.Count

    If candidates.Count = 1 Then
        Dim onlyName
        For Each onlyName In candidates.Keys
            relationshipName = onlyName
            reversedDirection = CBool(directions(onlyName))
            Exit For
        Next
    End If
End Function

Function IsClassCompatible(actualClass, expectedClass)
    IsClassCompatible = False

    Dim actualValue, expectedValue
    actualValue = Trim(CStr(actualClass))
    expectedValue = Trim(CStr(expectedClass))

    If actualValue = "" Or expectedValue = "" Then Exit Function

    If LCase(actualValue) = LCase(expectedValue) Then
        IsClassCompatible = True
        Exit Function
    End If

    Dim currentClass, guard
    currentClass = actualValue
    guard = 0

    Do While classParentMap.Exists(currentClass) And guard < 32
        currentClass = classParentMap(currentClass)
        If LCase(currentClass) = LCase(expectedValue) Then
            IsClassCompatible = True
            Exit Function
        End If
        guard = guard + 1
    Loop
End Function

Function NormalizeDAFElementType(sourceStereo)
    Dim s
    s = Trim(CStr(sourceStereo))

    If legacyElementTypeMap.Exists(s) Then
        s = legacyElementTypeMap(s)
    End If

    NormalizeDAFElementType = CanonicalDAFClassName(s)
End Function

Function CanonicalDAFClassName(value)
    Dim s, key
    s = Trim(CStr(value))
    CanonicalDAFClassName = s

    If s = "" Then Exit Function

    ' classMap is case-insensitive, but RDF local names are case-sensitive.
    ' Return the exact canonical spelling embedded from the M2 contract.
    For Each key In classMap.Keys
        If LCase(CStr(key)) = LCase(s) Then
            CanonicalDAFClassName = CStr(key)
            Exit Function
        End If
    Next
End Function

Sub WriteLegacyElementInjectedProperties(el, sourceStereo, currentClass)
    If Not legacyElementInjectedPropertyMap.Exists(sourceStereo) Then Exit Sub

    Dim definition, parts, predicateLocal, valueKind, value
    definition = legacyElementInjectedPropertyMap(sourceStereo)
    parts = Split(definition, "|")

    If UBound(parts) < 2 Then Exit Sub

    predicateLocal = parts(0)
    valueKind = LCase(parts(1))
    value = parts(2)

    ' If the element already carries the current property explicitly, trust
    ' the explicit current value and do not inject a duplicate migration value.
    Dim currentPropertyName
    currentPropertyName = CurrentPropertyNameFromPredicate(currentClass, predicateLocal)
    If currentPropertyName <> "" Then
        If HasTaggedValue(el, currentPropertyName) Then Exit Sub
    End If

    Select Case valueKind
        Case "boolean"
            W "    dafp:" & TurtleLocal(predicateLocal) & " " _
                & BooleanLiteral(LCase(value) = "true") & " ;"
        Case Else
            W "    dafp:" & TurtleLocal(predicateLocal) & " " & Lit(value) & " ;"
    End Select
End Sub

Function CurrentPropertyNameFromPredicate(className, predicateLocal)
    CurrentPropertyNameFromPredicate = ""

    Dim key, parts
    For Each key In propertyMap.Keys
        If LCase(Left(key, Len(className) + 1)) = LCase(className & "|") Then
            parts = Split(propertyMap(key), "|")
            If LCase(parts(0)) = LCase(predicateLocal) Then
                CurrentPropertyNameFromPredicate = Mid(key, Len(className) + 2)
                Exit Function
            End If
        End If
    Next
End Function

Function HasTaggedValue(el, tagName)
    HasTaggedValue = False

    Dim tv
    For Each tv In el.TaggedValues
        If LCase(Trim(CStr(tv.Name))) = LCase(Trim(CStr(tagName))) Then
            HasTaggedValue = True
            Exit Function
        End If
    Next
End Function

Function GetEndpointIri(elementId)
    If elementIriById.Exists(CStr(elementId)) Then
        GetEndpointIri = elementIriById(CStr(elementId))
        Exit Function
    End If

    If externalEndpointIriById.Exists(CStr(elementId)) Then
        GetEndpointIri = externalEndpointIriById(CStr(elementId))
        Exit Function
    End If

    On Error Resume Next
    Dim extEl
    Set extEl = Repository.GetElementByID(CLng(elementId))
    If Err.Number <> 0 Then
        Err.Clear
        Set extEl = Nothing
    End If
    On Error GoTo 0

    If extEl Is Nothing Then
        Dim fallbackIri
        fallbackIri = "m:external_element_id_" & SafeLocal(CStr(elementId))
        externalEndpointIriById.Add CStr(elementId), fallbackIri
        externalEndpointTypeById.Add CStr(elementId), ""
        externalMappedDAFTypeById.Add CStr(elementId), ""
        externalMappedDAFStatusById.Add CStr(elementId), ""
        externalSourceProfileById.Add CStr(elementId), ""
        WriteExternalEndpointFallback elementId, fallbackIri
        externalEndpointCount = externalEndpointCount + 1
        GetEndpointIri = fallbackIri
        Exit Function
    End If

    Dim endpointIri, sourceStereo, normalizedType
    Dim mappedType, mappingStatus, mappingConfidence, mappingBasis, mappingRule
    endpointIri = ResourceIri("external_element", extEl.ElementGUID)
    sourceStereo = FindDAFElementStereotype(extEl)
    normalizedType = NormalizeDAFElementType(sourceStereo)

    DetermineExternalDAFMapping extEl, sourceStereo, normalizedType, _
        mappedType, mappingStatus, mappingConfidence, mappingBasis, mappingRule

    externalEndpointIriById.Add CStr(elementId), endpointIri
    externalEndpointTypeById.Add CStr(elementId), normalizedType
    externalMappedDAFTypeById.Add CStr(elementId), mappedType
    externalMappedDAFStatusById.Add CStr(elementId), mappingStatus

    Dim sourceFQForIndex, sourceProfileForIndex
    sourceFQForIndex = SafeElementFQStereotype(extEl)
    sourceProfileForIndex = ExtractProfileName(sourceFQForIndex)
    If sourceProfileForIndex = "" Then sourceProfileForIndex = ExtractProfileName(extEl.StereotypeEx)
    externalSourceProfileById.Add CStr(elementId), sourceProfileForIndex

    externalEndpointCount = externalEndpointCount + 1

    WriteExternalEndpoint extEl, endpointIri, sourceStereo, normalizedType

    GetEndpointIri = endpointIri
End Function

Function GetEndpointSemanticType(elementId)
    If elementStereoById.Exists(CStr(elementId)) Then
        GetEndpointSemanticType = elementStereoById(CStr(elementId))
        Exit Function
    End If

    If externalEndpointTypeById.Exists(CStr(elementId)) Then
        GetEndpointSemanticType = externalEndpointTypeById(CStr(elementId))
        Exit Function
    End If

    ' Force creation/resolution of the external endpoint metadata.
    Dim ignoredIri
    ignoredIri = GetEndpointIri(elementId)

    If externalEndpointTypeById.Exists(CStr(elementId)) Then
        GetEndpointSemanticType = externalEndpointTypeById(CStr(elementId))
    Else
        GetEndpointSemanticType = ""
    End If
End Function

Sub WriteExternalEndpoint(extEl, endpointIri, sourceStereo, normalizedType)
    If externalEndpointWrittenById.Exists(CStr(extEl.ElementID)) Then Exit Sub
    externalEndpointWrittenById.Add CStr(extEl.ElementID), True

    Dim fqStereo, profileName, metaTypeValue, fqNameValue
    Dim targetClass, mappingStatus, confidence, mappingBasis, mappingRule
    fqStereo = SafeElementFQStereotype(extEl)
    profileName = ExtractProfileName(fqStereo)
    If profileName = "" Then profileName = ExtractProfileName(extEl.StereotypeEx)
    metaTypeValue = SafeElementMetaType(extEl)
    fqNameValue = SafeElementFQName(extEl)

    DetermineExternalDAFMapping extEl, sourceStereo, normalizedType, _
        targetClass, mappingStatus, confidence, mappingBasis, mappingRule

    IncrementCount externalProfileCounts, ReportBucket(profileName)
    IncrementCount externalMetaTypeCounts, ReportBucket(metaTypeValue)
    IncrementCount externalStereotypeCounts, ReportBucket(extEl.StereotypeEx)
    If fqStereo <> "" Then externalFQStereotypeCount = externalFQStereotypeCount + 1

    W "# First-level external element: " & OneLine(extEl.Name)
    W endpointIri

    If normalizedType <> "" And classMap.Exists(normalizedType) Then
        ' Explicit DAF type is factual source metadata.
        W "    a dafi:ExternalElement, dafi:ExternalEndpoint, daf:" & TurtleLocal(normalizedType) & " ;"
        W "    dafi:resolvedDAFType " & Lit(normalizedType) & " ;"
        W "    dafi:transformationApplied true ;"
    ElseIf mappingStatus = "applied" And targetClass <> "" Then
        ' Trusted ancestor/sibling transformation: retain the source resource
        ' while asserting its DAF 6.3 semantic type.
        W "    a dafi:ExternalElement, dafi:ExternalEndpoint, daf:" & TurtleLocal(targetClass) & " ;"
        W "    dafi:resolvedDAFType " & Lit(targetClass) & " ;"
        W "    dafi:transformationApplied true ;"
        If profileName <> "" Then
            W "    dafi:transformedFromProfile " & Lit(profileName) & " ;"
        End If
    Else
        W "    a dafi:ExternalElement, dafi:ExternalEndpoint ;"
    End If

    W "    rdfs:label " & Lit(extEl.Name) & " ;"
    W "    dafm:eaGuid " & Lit(extEl.ElementGUID) & " ;"
    W "    dafi:externalToExport true ;"
    W "    dafi:importDepth ""1""^^xsd:int ;"
    W "    dafi:sourceElementType " & Lit(extEl.Type) & " ;"
    W "    dafi:sourceMetaType " & Lit(metaTypeValue) & " ;"
    W "    dafm:sourceStereotype " & Lit(extEl.StereotypeEx) & " ;"

    If fqStereo <> "" Then
        W "    dafi:sourceFQStereotype " & Lit(fqStereo) & " ;"
    End If

    If fqNameValue <> "" Then
        W "    dafi:sourceFQName " & Lit(fqNameValue) & " ;"
    End If

    If profileName <> "" Then
        W "    dafi:sourceProfile " & Lit(profileName) & " ;"
    End If

    If Trim(CStr(extEl.Alias)) <> "" Then
        W "    dafi:sourceAlias " & Lit(extEl.Alias) & " ;"
    End If

    If Trim(CStr(extEl.Status)) <> "" Then
        W "    dafi:sourceStatus " & Lit(extEl.Status) & " ;"
    End If

    If Trim(CStr(extEl.Version)) <> "" Then
        W "    dafi:sourceVersion " & Lit(extEl.Version) & " ;"
    End If

    If Trim(CStr(extEl.Author)) <> "" Then
        W "    dafi:sourceAuthor " & Lit(extEl.Author) & " ;"
    End If

    If Trim(CStr(extEl.Notes)) <> "" Then
        W "    dcterms:description " & Lit(extEl.Notes) & " ;"
    End If

    WriteExternalPackageMetadata extEl
    WriteExternalClassifierMetadata extEl

    ' Close with the original EA base element type.
    W "    dafi:sourceElementType " & Lit(extEl.Type) & " ."
    W ""

    ExportExternalElementTaggedValues extEl, endpointIri
    WriteExternalElementSemanticMapping extEl, endpointIri, sourceStereo, normalizedType

    ' IMPORTANT: no traversal of extEl.Connectors here.
    ' External element import depth is deliberately fixed at one.
End Sub

Sub DetermineExternalDAFMapping(extEl, sourceStereo, normalizedType, _
        ByRef targetClass, ByRef mappingStatus, ByRef confidence, _
        ByRef basis, ByRef ruleName)

    targetClass = ""
    mappingStatus = ""
    confidence = ""
    basis = ""
    ruleName = ""

    If normalizedType <> "" And classMap.Exists(normalizedType) Then
        targetClass = CanonicalDAFClassName(normalizedType)
        mappingStatus = "already-daf"
        confidence = "exact"
        basis = "explicit DAF stereotype"
        ruleName = "explicit-daf-type"
        Exit Sub
    End If

    Dim fqStereo, localFQStereo, rawStereo, metaTypeValue, elementTypeValue
    Dim candidateKey, ruleParts

    fqStereo = SafeElementFQStereotype(extEl)
    localFQStereo = LocalStereotypeName(fqStereo)
    rawStereo = FirstStereotypeToken(extEl.StereotypeEx)
    metaTypeValue = SafeElementMetaType(extEl)
    elementTypeValue = Trim(CStr(extEl.Type))
    candidateKey = ""

    ' Exact fully-qualified source technology is strongest and permits trusted
    ' profile transformations.
    If fqStereo <> "" And externalMappingRuleMap.Exists(fqStereo) Then
        candidateKey = fqStereo
    ElseIf localFQStereo <> "" And externalMappingRuleMap.Exists(localFQStereo) Then
        candidateKey = localFQStereo
    ElseIf rawStereo <> "" And externalMappingRuleMap.Exists(rawStereo) Then
        candidateKey = rawStereo
    ElseIf Trim(CStr(sourceStereo)) <> "" And externalMappingRuleMap.Exists(sourceStereo) Then
        candidateKey = sourceStereo
    ElseIf metaTypeValue <> "" And externalMappingRuleMap.Exists(metaTypeValue) Then
        candidateKey = metaTypeValue
    ElseIf elementTypeValue <> "" And externalMappingRuleMap.Exists(elementTypeValue) Then
        candidateKey = elementTypeValue
    End If

    If candidateKey <> "" Then
        ruleParts = Split(externalMappingRuleMap(candidateKey), "|")
        targetClass = CanonicalDAFClassName(ruleParts(0))
        mappingStatus = ruleParts(1)
        confidence = ruleParts(2)
        basis = ruleParts(3)
        ruleName = "external-" & SafeLocal(candidateKey) & "-to-" & SafeLocal(targetClass)
    End If
End Sub

Function LocalStereotypeName(fqStereo)
    Dim s, p
    s = Trim(CStr(fqStereo))
    LocalStereotypeName = s

    p = InStrRev(s, "::")
    If p > 0 Then LocalStereotypeName = Mid(s, p + 2)
End Function

Function FirstStereotypeToken(stereotypeEx)
    Dim raw, tokens
    raw = Trim(CStr(stereotypeEx))
    FirstStereotypeToken = raw

    If InStr(raw, ",") > 0 Then
        tokens = Split(raw, ",")
        FirstStereotypeToken = Trim(CStr(tokens(0)))
    End If
End Function

Function IsTrustedTransformationProfile(profileName)
    Dim p
    p = LCase(Trim(CStr(profileName)))

    IsTrustedTransformationProfile = _
        (p = "chronos" Or p = "tmf" Or p = "bizbok" Or p = "togaf")
End Function

Sub WriteExternalElementSemanticMapping(extEl, endpointIri, sourceStereo, normalizedType)
    Dim targetClass, mappingStatus, confidence, basis, ruleName
    DetermineExternalDAFMapping extEl, sourceStereo, normalizedType, _
        targetClass, mappingStatus, confidence, basis, ruleName

    If targetClass = "" Then Exit Sub

    Dim mapIri
    mapIri = ResourceIri("semantic_mapping", extEl.ElementGUID)

    W endpointIri & " dafi:hasSemanticMapping " & mapIri & " ."
    W mapIri
    W "    a dafi:SemanticMapping ;"
    W "    dafi:sourceResource " & endpointIri & " ;"
    W "    dafi:targetDAFType daf:" & TurtleLocal(targetClass) & " ;"
    W "    dafi:mappingRule " & Lit(ruleName) & " ;"
    W "    dafi:mappingStatus " & Lit(mappingStatus) & " ;"
    W "    dafi:mappingConfidence " & Lit(confidence) & " ;"
    W "    dafi:mappingBasis " & Lit(basis) & " ."
    W ""

    externalElementMappingCount = externalElementMappingCount + 1

    Dim reportSource, sourceProfile
    reportSource = FirstStereotypeToken(extEl.StereotypeEx)
    sourceProfile = ExtractProfileName(SafeElementFQStereotype(extEl))

    IncrementCount externalElementMappingCounts, _
        mappingStatus & ": " & ReportBucket(reportSource) & " -> " & targetClass

    If mappingStatus = "applied" Then
        externalAppliedElementTransformationCount = externalAppliedElementTransformationCount + 1
        IncrementCount trustedElementTransformationCounts, _
            ReportBucket(sourceProfile) & ": " & ReportBucket(reportSource) & " -> " & targetClass
    ElseIf mappingStatus = "candidate" Then
        externalCandidateElementMappingCount = externalCandidateElementMappingCount + 1
    End If
End Sub

Function GetEndpointCandidateDAFType(elementId)
    GetEndpointCandidateDAFType = ""

    If elementStereoById.Exists(CStr(elementId)) Then
        If classMap.Exists(elementStereoById(CStr(elementId))) Then
            GetEndpointCandidateDAFType = CanonicalDAFClassName(elementStereoById(CStr(elementId)))
        End If
        Exit Function
    End If

    If externalMappedDAFTypeById.Exists(CStr(elementId)) Then
        GetEndpointCandidateDAFType = externalMappedDAFTypeById(CStr(elementId))
    End If
End Function

Function GetEndpointAppliedDAFType(elementId)
    GetEndpointAppliedDAFType = ""

    If elementStereoById.Exists(CStr(elementId)) Then
        If classMap.Exists(elementStereoById(CStr(elementId))) Then
            GetEndpointAppliedDAFType = CanonicalDAFClassName(elementStereoById(CStr(elementId)))
        End If
        Exit Function
    End If

    If externalMappedDAFTypeById.Exists(CStr(elementId)) _
        And externalMappedDAFStatusById.Exists(CStr(elementId)) Then

        Dim status
        status = LCase(Trim(CStr(externalMappedDAFStatusById(CStr(elementId)))))

        If status = "applied" Or status = "already-daf" Then
            GetEndpointAppliedDAFType = externalMappedDAFTypeById(CStr(elementId))
        End If
    End If
End Function

Function GetEndpointSourceProfile(elementId)
    GetEndpointSourceProfile = ""

    If elementIriById.Exists(CStr(elementId)) Then
        GetEndpointSourceProfile = "DAF"
        Exit Function
    End If

    If externalSourceProfileById.Exists(CStr(elementId)) Then
        GetEndpointSourceProfile = externalSourceProfileById(CStr(elementId))
    End If
End Function


Function SafeElementFQStereotype(el)
    SafeElementFQStereotype = ""

    On Error Resume Next
    Dim value
    value = CStr(el.FQStereotype)
    If Err.Number = 0 Then SafeElementFQStereotype = value
    Err.Clear
    On Error GoTo 0
End Function

Function SafeElementFQName(el)
    SafeElementFQName = ""

    On Error Resume Next
    Dim value
    value = CStr(el.FQName)
    If Err.Number = 0 Then SafeElementFQName = value
    Err.Clear
    On Error GoTo 0
End Function

Function SafeConnectorFQStereotype(c)
    SafeConnectorFQStereotype = ""

    On Error Resume Next
    Dim value
    value = CStr(c.FQStereotype)
    If Err.Number = 0 Then SafeConnectorFQStereotype = value
    Err.Clear
    On Error GoTo 0
End Function

Function SafeConnectorMetaType(c)
    SafeConnectorMetaType = ""

    On Error Resume Next
    Dim value
    value = CStr(c.MetaType)
    If Err.Number = 0 Then SafeConnectorMetaType = value
    Err.Clear
    On Error GoTo 0
End Function

Function ReportBucket(value)
    Dim s
    s = Trim(CStr(value))
    If s = "" Then
        ReportBucket = "<none>"
    Else
        ReportBucket = s
    End If
End Function

Sub WriteExternalPackageMetadata(extEl)
    On Error Resume Next

    Dim p
    Set p = Repository.GetPackageByID(CLng(extEl.PackageID))

    If Err.Number = 0 And Not p Is Nothing Then
        W "    dafi:sourcePackageName " & Lit(p.Name) & " ;"
        W "    dafi:sourcePackageGuid " & Lit(p.PackageGUID) & " ;"
    End If

    Err.Clear
    On Error GoTo 0
End Sub

Sub WriteExternalClassifierMetadata(extEl)
    On Error Resume Next

    Dim classifierId
    classifierId = CLng(extEl.ClassifierID)

    If Err.Number <> 0 Then
        Err.Clear
        On Error GoTo 0
        Exit Sub
    End If

    If classifierId <= 0 Then
        On Error GoTo 0
        Exit Sub
    End If

    W "    dafi:sourceClassifierId " & Lit(CStr(classifierId)) & " ;"

    Dim classifier
    Set classifier = Repository.GetElementByID(classifierId)

    If Err.Number = 0 And Not classifier Is Nothing Then
        W "    dafi:sourceClassifierGuid " & Lit(classifier.ElementGUID) & " ;"
        W "    dafi:sourceClassifierName " & Lit(classifier.Name) & " ;"
    End If

    Err.Clear
    On Error GoTo 0
End Sub

Sub ExportExternalElementTaggedValues(extEl, ownerIri)
    Dim i, tv, rawValue, tagIri
    i = 0

    For Each tv In extEl.TaggedValues
        i = i + 1
        rawValue = TaggedValueActualValue(tv)
        rawTaggedValueCount = rawTaggedValueCount + 1
        tagIri = ResourceIriWithSuffix("external_tag", extEl.ElementGUID, CStr(i))

        W ownerIri & " dafm:hasTaggedValue " & tagIri & " ."
        W tagIri
        W "    a dafm:TaggedValue ;"
        W "    dafm:tagName " & Lit(tv.Name) & " ;"
        W "    dafm:tagValue " & Lit(rawValue) & " ;"
        W "    dafm:ownerKind ""external-element"" ."
        W ""
    Next
End Sub

Function ExtractProfileName(stereotypeEx)
    ExtractProfileName = ""

    Dim raw, tokens, token, i, p
    raw = Trim(CStr(stereotypeEx))
    If raw = "" Then Exit Function

    tokens = Split(raw, ",")
    For i = 0 To UBound(tokens)
        token = Trim(tokens(i))
        p = InStr(token, "::")
        If p > 1 Then
            ExtractProfileName = Left(token, p - 1)
            Exit Function
        End If
    Next
End Function

Function SafeElementMetaType(el)
    SafeElementMetaType = ""

    On Error Resume Next
    Dim value
    value = CStr(el.MetaType)

    If Err.Number = 0 Then
        SafeElementMetaType = value
    End If

    Err.Clear
    On Error GoTo 0
End Function

Sub WriteExternalEndpointFallback(elementId, endpointIri)
    W "# First-level external element unavailable through EA API"
    W endpointIri
    W "    a dafi:ExternalElement, dafi:ExternalEndpoint ;"
    W "    rdfs:label " & Lit("EA ElementID " & CStr(elementId)) & " ;"
    W "    dafi:externalToExport true ;"
    W "    dafi:importDepth ""1""^^xsd:int ."
    W ""
End Sub

Function BooleanLiteral(value)
    If CBool(value) Then
        BooleanLiteral = """true""^^xsd:boolean"
    Else
        BooleanLiteral = """false""^^xsd:boolean"
    End If
End Function

Sub ExportConnectorTaggedValues(c, ownerIri)
    Dim i, tv, rawValue, tagIri
    i = 0

    For Each tv In c.TaggedValues
        i = i + 1
        rawValue = TaggedValueActualValue(tv)
        rawTaggedValueCount = rawTaggedValueCount + 1
        tagIri = ResourceIriWithSuffix("connector_tag", c.ConnectorGUID, CStr(i))

        W ownerIri & " dafm:hasTaggedValue " & tagIri & " ."
        W tagIri
        W "    a dafm:TaggedValue ;"
        W "    dafm:tagName " & Lit(tv.Name) & " ;"
        W "    dafm:tagValue " & Lit(rawValue) & " ;"
        W "    dafm:ownerKind ""connector"" ."
        W ""
    Next
End Sub

Function FindDAFElementStereotype(el)
    Dim candidate
    candidate = FindDAFStereotypeToken(el.StereotypeEx, True)
    If candidate = "" Then candidate = FindDAFStereotypeToken(el.Stereotype, True)
    FindDAFElementStereotype = candidate
End Function

Function FindDAFRelationshipStereotype(c)
    Dim candidate
    candidate = FindDAFStereotypeToken(c.StereotypeEx, False)
    If candidate = "" Then candidate = FindDAFStereotypeToken(c.Stereotype, False)
    FindDAFRelationshipStereotype = candidate
End Function

Function FindDAFStereotypeToken(stereotypeText, isElement)
    FindDAFStereotypeToken = ""

    Dim raw, tokens, token, i, p, profile, localName
    raw = Trim(CStr(stereotypeText))
    If raw = "" Then Exit Function

    tokens = Split(raw, ",")

    ' First preference: explicit DAF::<stereotype>
    For i = 0 To UBound(tokens)
        token = Trim(tokens(i))
        p = InStr(token, "::")
        If p > 0 Then
            profile = Left(token, p - 1)
            localName = Mid(token, p + 2)
            If LCase(profile) = LCase(PROFILE_NAME) Then
                FindDAFStereotypeToken = localName
                Exit Function
            End If
        End If
    Next

    ' Second preference: exact match to current semantic contract.
    For i = 0 To UBound(tokens)
        token = Trim(tokens(i))
        If isElement Then
            If classMap.Exists(token) Then
                FindDAFStereotypeToken = token
                Exit Function
            End If
        Else
            If relationshipMap.Exists(token) Then
                FindDAFStereotypeToken = token
                Exit Function
            End If
        End If
    Next

    ' Legacy DAF heuristic: unqualified DAF stereotypes conventionally use
    ' d + Uppercase (for example dCapability) or d_.
    For i = 0 To UBound(tokens)
        token = Trim(tokens(i))
        If IsLikelyLegacyDafName(token) Then
            FindDAFStereotypeToken = token
            Exit Function
        End If
    Next
End Function

Function IsLikelyLegacyDafName(value)
    IsLikelyLegacyDafName = False

    Dim s, secondChar
    s = Trim(CStr(value))
    If Len(s) < 2 Then Exit Function
    If Left(s, 1) <> "d" Then Exit Function

    secondChar = Mid(s, 2, 1)
    If (secondChar >= "A" And secondChar <= "Z") Or secondChar = "_" Then
        IsLikelyLegacyDafName = True
    End If
End Function

Function TransformLegacySemanticValue(dafStereo, propertyName, rawValue, targetType)
    TransformLegacySemanticValue = rawValue

    ' DAF 6.3 application satisfaction is represented as an integer percentage.
    ' Historical EuroCOM values used a five-level qualitative enumeration.
    ' Convert only the confirmed dApplicationComponent satisfaction properties;
    ' raw EA tagged values remain preserved separately as provenance.
    If LCase(Trim(CStr(dafStereo))) <> "dapplicationcomponent" Then Exit Function

    Dim p
    p = LCase(Trim(CStr(propertyName)))
    If p <> "bizsatisfaction" And p <> "itsatisfaction" Then Exit Function

    If LCase(Trim(CStr(targetType))) <> "int" _
        And LCase(Trim(CStr(targetType))) <> "integer" _
        And LCase(Trim(CStr(targetType))) <> "long" Then Exit Function

    Dim originalValue, normalizedValue
    originalValue = Trim(CStr(rawValue))
    normalizedValue = ""

    Select Case LCase(originalValue)
        Case "highly dissatisfied"
            normalizedValue = "0"
        Case "not satisfied"
            normalizedValue = "25"
        Case "moderately satisfied"
            normalizedValue = "50"
        Case "satisfied"
            normalizedValue = "75"
        Case "highly satisfied"
            normalizedValue = "100"
    End Select

    If normalizedValue <> "" Then
        TransformLegacySemanticValue = normalizedValue
        IncrementCount satisfactionConversionCounts, _
            dafStereo & "." & propertyName & ": " _
            & originalValue & " -> " & normalizedValue & "%"
    End If
End Function

Function SemanticLiteral(rawValue, targetType)
    Dim v
    v = Trim(CStr(rawValue))

    Select Case LCase(targetType)
        Case "string"
            SemanticLiteral = Lit(rawValue)

        Case "boolean"
            Select Case LCase(v)
                Case "true", "1", "yes", "y", "on"
                    SemanticLiteral = """true""^^xsd:boolean"
                Case "false", "0", "no", "n", "off"
                    SemanticLiteral = """false""^^xsd:boolean"
                Case Else
                    SemanticLiteral = ""
            End Select

        Case "int", "integer", "long"
            If IsNumeric(v) Then
                On Error Resume Next
                Dim numericValue, n
                numericValue = CDbl(v)
                If Err.Number = 0 And numericValue = Fix(numericValue) Then
                    n = CLng(numericValue)
                    If Err.Number = 0 Then
                        SemanticLiteral = """" & CStr(n) & """^^xsd:" & targetType
                    Else
                        SemanticLiteral = ""
                    End If
                Else
                    SemanticLiteral = ""
                End If
                Err.Clear
                On Error GoTo 0
            Else
                SemanticLiteral = ""
            End If

        Case "float", "double", "decimal"
            If IsNumeric(v) Then
                Dim f
                f = Replace(CStr(CDbl(v)), ",", ".")
                SemanticLiteral = """" & f & """^^xsd:" & targetType
            Else
                SemanticLiteral = ""
            End If

        Case "date"
            If IsDate(v) Then
                SemanticLiteral = TypedLit(IsoDate(CDate(v)), "date")
            ElseIf LooksLikeIsoDate(v) Then
                SemanticLiteral = TypedLit(v, "date")
            Else
                SemanticLiteral = ""
            End If

        Case "datetime"
            If IsDate(v) Then
                SemanticLiteral = TypedLit(IsoDateTime(CDate(v)), "dateTime")
            ElseIf LooksLikeIsoDateTime(v) Then
                SemanticLiteral = TypedLit(v, "dateTime")
            Else
                SemanticLiteral = ""
            End If

        Case Else
            SemanticLiteral = Lit(rawValue)
    End Select
End Function

Function TaggedValueActualValue(tv)
    Dim v
    v = CStr(tv.Value)

    If LCase(Trim(v)) = "<memo>" Then
        TaggedValueActualValue = CStr(tv.Notes)
    Else
        TaggedValueActualValue = v
    End If
End Function

Function PackageIri(packageId)
    If packageIriById.Exists(CStr(packageId)) Then
        PackageIri = packageIriById(CStr(packageId))
    Else
        PackageIri = "m:package_unknown_" & CStr(packageId)
    End If
End Function

Function ElementIri(elementId)
    If elementIriById.Exists(CStr(elementId)) Then
        ElementIri = elementIriById(CStr(elementId))
    Else
        ElementIri = "m:element_unknown_" & CStr(elementId)
    End If
End Function

Function ResourceIri(kind, guidValue)
    Dim g
    g = Replace(NormalizeGuid(guidValue), "-", "_")
    ResourceIri = "m:" & kind & "_" & g
End Function

Function ResourceIriWithSuffix(kind, guidValue, suffix)
    Dim g
    g = Replace(NormalizeGuid(guidValue), "-", "_")
    ResourceIriWithSuffix = "m:" & kind & "_" & g & "_" & SafeLocal(suffix)
End Function

Function NormalizeGuid(guidValue)
    Dim s
    s = LCase(Trim(CStr(guidValue)))
    s = Replace(s, "{", "")
    s = Replace(s, "}", "")
    NormalizeGuid = s
End Function

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

Function TurtleLocal(value)
    TurtleLocal = SafeLocal(value)
End Function

Function SafeLocal(value)
    Dim s, i, ch, result
    s = CStr(value)
    result = ""

    For i = 1 To Len(s)
        ch = Mid(s, i, 1)
        If (ch >= "A" And ch <= "Z") Or (ch >= "a" And ch <= "z") _
            Or (ch >= "0" And ch <= "9") Or ch = "_" Or ch = "-" Then
            result = result & ch
        Else
            result = result & "_"
        End If
    Next

    If result = "" Then result = "unnamed"
    If Left(result, 1) >= "0" And Left(result, 1) <= "9" Then result = "n_" & result

    SafeLocal = result
End Function

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

Function IsoDateTime(d)
    IsoDateTime = Year(d) & "-" & Pad2(Month(d)) & "-" & Pad2(Day(d)) _
        & "T" & Pad2(Hour(d)) & ":" & Pad2(Minute(d)) & ":" & Pad2(Second(d))
End Function

Function IsoDate(d)
    IsoDate = Year(d) & "-" & Pad2(Month(d)) & "-" & Pad2(Day(d))
End Function

Function Pad2(n)
    If n < 10 Then
        Pad2 = "0" & CStr(n)
    Else
        Pad2 = CStr(n)
    End If
End Function

Function LooksLikeIsoDate(v)
    Dim re
    Set re = CreateObject("VBScript.RegExp")
    re.Pattern = "^\d{4}-\d{2}-\d{2}$"
    LooksLikeIsoDate = re.Test(CStr(v))
End Function

Function LooksLikeIsoDateTime(v)
    Dim re
    Set re = CreateObject("VBScript.RegExp")
    re.Pattern = "^\d{4}-\d{2}-\d{2}T"
    LooksLikeIsoDateTime = re.Test(CStr(v))
End Function

Function IIfSuffix(condition, trueValue, falseValue)
    If condition Then
        IIfSuffix = trueValue
    Else
        IIfSuffix = falseValue
    End If
End Function

Sub IncrementCount(dict, key)
    If dict.Exists(key) Then
        dict(key) = CLng(dict(key)) + 1
    Else
        dict.Add key, 1
    End If
End Sub

Sub WriteAuditSummary()
    Report "SUMMARY"
    Report "Packages exported: " & packageCount
    Report "DAF elements exported: " & elementCount
    Report "Relationships exported: " & relationshipCount
    Report "Semantic DAF relationships resolved: " & semanticRelationshipCount
    Report "  resolved by exact current stereotype: " & relationshipResolvedExactCount
    Report "  resolved deterministically from endpoint types: " & relationshipResolvedByEndpointsCount
    Report "  semantic direction reversed from EA Client/Supplier: " & relationshipDirectionReversedCount
    Report "Generic/unresolved connectors exported: " & genericConnectorCount
    Report "Ambiguous endpoint relationship resolutions: " & ambiguousRelationshipCount
    Report "Materialized relationship projection triples: " & projectionCount
    Report "External/cross-boundary connectors preserved: " & externalConnectorCount
    Report "External relationships explicitly represented: " & externalRelationshipCount
    Report "First-level external elements fully imported: " & externalEndpointCount
    Report "External elements with EA FQStereotype recovered: " & externalFQStereotypeCount
    Report "External connectors with EA FQStereotype recovered: " & externalConnectorFQStereotypeCount
    Report "External element SemanticMappings emitted: " & externalElementMappingCount
    Report "  trusted foreign elements transformed to DAF: " & externalAppliedElementTransformationCount
    Report "  non-trusted/cautious element mapping candidates: " & externalCandidateElementMappingCount
    Report "External relationship SemanticMappings emitted: " & externalRelationshipMappingCount
    Report "  trusted source relationships transformed to DAF: " & externalAppliedRelationshipTransformationCount
    Report "  structural relationship mapping candidates: " & externalCandidateRelationshipMappingCount
    Report "Raw tagged values preserved: " & rawTaggedValueCount
    Report "Mapped semantic property values emitted: " & mappedPropertyValueCount
    Report "Legacy qualitative satisfaction values converted to percentage: " _
        & SumDictionaryCounts(satisfactionConversionCounts)
    Report "Suppressed legacy ID/Id/id tags: " & suppressedIdTagCount
    Report "Unresolved object-property references: " & unresolvedObjectReferenceCount
    Report "Unnamed DAF elements: " & unnamedElementCount
    Report "Diagrams/views exported: 0 (deferred)"
    Report ""

    WriteCountDictionary "LEGACY ELEMENT MIGRATIONS APPLIED", legacyElementMigrationCounts
    WriteCountDictionary "LEGACY PROPERTY MIGRATIONS APPLIED", legacyPropertyMigrationCounts
    WriteCountDictionary "SATISFACTION ENUMERATION -> PERCENTAGE CONVERSIONS", satisfactionConversionCounts
    WriteCountDictionary "EXTERNAL SOURCE PROFILES (EA FQStereotype)", externalProfileCounts
    WriteCountDictionary "EXTERNAL SOURCE METATYPES", externalMetaTypeCounts
    WriteCountDictionary "EXTERNAL SOURCE STEREOTYPES", externalStereotypeCounts
    WriteCountDictionary "EXTERNAL ELEMENT SEMANTIC MAPPINGS", externalElementMappingCounts
    WriteCountDictionary "TRUSTED PROFILE ELEMENT TRANSFORMATIONS APPLIED", trustedElementTransformationCounts
    WriteCountDictionary "EXTERNAL RELATIONSHIP SOURCE PROFILES", externalRelationshipProfileCounts
    WriteCountDictionary "EXTERNAL RELATIONSHIP SEMANTIC MAPPINGS", externalRelationshipMappingCounts
    WriteCountDictionary "TRUSTED PROFILE RELATIONSHIP TRANSFORMATIONS APPLIED", trustedRelationshipTransformationCounts
    WriteCountDictionary "TRUSTED PROFILE RELATIONSHIPS WITH NO DAF 6.3 EQUIVALENT", trustedRelationshipNoEquivalentCounts
    WriteCountDictionary "LEGACY RELATIONSHIPS RESOLVED FROM M2 ENDPOINT TYPES", legacyRelationshipMigrationCounts
    WriteCountDictionary "UNRESOLVED / LEGACY DAF ELEMENT TYPES", unknownElementTypeCounts
    WriteCountDictionary "UNRESOLVED / LEGACY DAF RELATIONSHIP TYPES", unknownRelationshipTypeCounts
    WriteCountDictionary "RELATIONSHIP ENDPOINT TYPE MISMATCHES", relationshipEndpointMismatchCounts
    WriteCountDictionary "AMBIGUOUS RELATIONSHIP ENDPOINT PAIRS", ambiguousRelationshipCounts
    WriteCountDictionary "UNMAPPED TAGGED PROPERTIES (raw value preserved)", unmappedTagCounts
    WriteCountDictionary "INVALID OR UNRESOLVED TYPED VALUES (raw value preserved)", invalidTypedValueCounts

    Report "EXPORT COMPLETENESS"
    If elementCount = 0 Then
        Report "FAIL: No DAF elements were detected under the selected package."
    Else
        Report "PASS: DAF elements were exported."
    End If

    Report "NOTE: Semantic validation against DAF 6.3 / metamodel export 1.5.0 is intentionally performed by the Rust runtime, not by this EA exporter."
    Report "NOTE: Legacy migrations in exporter 0.5.0 are explicit DAF 6.3 mappings; relationship inference is only emitted when M2 endpoint typing identifies exactly one compatible RelationshipType."
    Report "NOTE: Out-of-scope elements directly referenced by in-scope DAF elements are fully imported at depth 1. Their other connectors are intentionally not traversed."
    Report "NOTE: Chronos, TMF, BIZBOK and TOGAF are trusted DAF ancestor/sibling source metamodels. Approved mappings are applied as DAF types while preserving the original external resource and provenance."
    Report "NOTE: Trusted source relationships are transformed only where an explicit or semantically defensible DAF 6.3 relationship equivalent exists. Otherwise they remain generic and are reported."
    Report "NOTE: Other external technologies remain candidate mappings only. Structural endpoint compatibility is reported with confidence=structural and is not treated as semantic equivalence."
    Report "NOTE: FQStereotype is used where supported by the EA Automation Interface to recover Profile::Stereotype identity for elements and connectors."
End Sub

Function SumDictionaryCounts(dict)
    Dim total, key
    total = 0

    For Each key In dict.Keys
        total = total + CLng(dict(key))
    Next

    SumDictionaryCounts = total
End Function

Sub WriteCountDictionary(title, dict)
    Report title
    If dict.Count = 0 Then
        Report "  none"
    Else
        Dim key
        For Each key In dict.Keys
            Report "  " & key & ": " & dict(key)
        Next
    End If
    Report ""
End Sub

Sub EnsureParentFolder(filePath)
    Dim fso, folder
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
    Dim fso, folder, base
    Set fso = CreateObject("Scripting.FileSystemObject")
    folder = fso.GetParentFolderName(filePath)
    base = fso.GetBaseName(filePath)

    If folder = "" Then
        ReplaceExtension = base & newExtension
    Else
        ReplaceExtension = folder & "\" & base & newExtension
    End If
End Function

Main
