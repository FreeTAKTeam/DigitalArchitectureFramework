# Telecom pack: mapping to DAF 7.0

This file records how the telecom industry pack is extracted from Sparx EA into DAF. It is the reference for the extraction script and for review of the generated pack.

The pack is **inspired by** telecom industry frameworks (TM Forum SID, eTOM, TAM, business metrics and capability map). It does not copy them. Names, definitions and decompositions are rewritten in DAF vocabulary; no text is lifted from the source notes or tagged values.

## Source
| Item | Value |
|---|---|
| Repository | `Industry Models` (SQL Server, opened through `IndustryModels_SQLServerShortcut.qea`) |
| Package | `TMF ODA` `{4F70B81E-0F34-4d2a-BD17-FB51EC7C8511}` › Model › `MODA` `{A604C031-A078-4cdd-9457-D84ECBBB62CB}` |
| Size | 897 packages, 15,814 elements, of which 1,101 in `Deleted*` packages |
| Target | DAF 7.0.0 Beta 5 (see [Metamodel changes](#metamodel-changes)) |

## Principles
* **Hybrid, leaning to instances.** Source stereotypes become plain DAF 7.0 instances. The metamodel is extended only with generic changes that any pack can use, never with telecom-specific metaclasses.
* **Explicit mapping only.** A stereotype is imported only if this file maps it. Nothing is guessed from names.
* **No silent drops.** Every element that is not imported is listed in the extraction report with its stereotype, source package and reason.
* **Facts are carried, prose is rewritten.** Codes, units, types and flags map to DAF properties. Descriptions, examples and formulas are written fresh.
* **No source numbering in the pack.** Source identifiers are kept only in the ledger, which is not published.

## Elements
| Source stereotype | Count | DAF 7.0 | Notes |
|---|---|---|---|
| `TMF_Process`, level 2-3 | 677 | `dBusinessProcess` | Unless linked to an ABE (next row). |
| `TMF_Process`, level 4-7 | 1,655 | `dBusinessService` | |
| `TMF_Process` linked to a `TMF_ABE` | 139 | `dBusinessService` | At every level. The link becomes `dBizServUsesDataEntity`. |
| `TMF_Process` without a level | 191 | by rule above | Level derived from package depth under the nearest process with a known level; still unknown → excluded and reported. |
| `TMF_Application` | 483 | `dLogicalAppComponent` | |
| `TMF_ABE` | 362 | `dDataEntity` | |
| `TMF_BusinessEntity` | 1,715 | `dModelClass` | |
| `TMF_Function` | 1,169 | `dApplicationFunction` | |
| `TMF_AF` | 349 | `dApplicationFunction` | A parent function; its children sit in its package. |
| `TMF_Capability` | 534 | `dCapability` | Has no links in the source; linking is a follow-up, not extraction. |
| `TMF_Metric` | 2,846 | `dMeasurementIndicator` | |
| `TMF_MetricGroup`, top level | — | `dMeasurementCategory` | Linked to its groups with `dCategoryaggregatesGroups`. |
| `TMF_MetricGroup`, below top level | — | `dMeasurementGrouping` | Deeper levels are flattened. |
| `TMF_Domain` | 13 | package only | No element. |
| Enumeration, DataType used by a model class attribute | — | UML Enumeration, DataType | Names and literals rewritten. Unused ones are dropped. |

## Tagged values
| Source tag | DAF 7.0 | Treatment |
|---|---|---|
| Process / Function / Application / BusinessCapability Identifier, FunctionID, UID, gid, tid, egid, DomainID | `Identifier` | New pack key (see [Pack identity](#pack-identity)). Source id to the ledger only. |
| BriefDescription, ShortDescription, Characteristics, Definition, Comment | element notes; `Definition` on KPIs and groups | Written fresh in DAF vocabulary. |
| TangibleExamples, DecompositionExamples, References | — | Dropped. |
| `TMF_Capability` HierarchyLevel | `dCapability.HierarchyLevel` | Carried. |
| HierarchyLevel on other stereotypes | — | Derived from the package structure. |
| `TMF_Metric` units | `dMeasurementIndicator.UnitOfMeasure` | UCUM code where possible. |
| `TMF_Metric` txtformula, numerator, denominator | `dMeasurementIndicator.Definition` | Restated as a formula over pack KPI names. |
| `TMF_Metric` category1-3, metrictype, group | `dMeasurementCategory`, `dMeasurementGrouping.MeasurementCategory` | Pack names. |
| Maturity, TMFStatus, Issue, Comment, SortID, Origin, system ID, entrydate, busvalue, IsCoreEntity, RSA_GUID | — | Dropped: editorial metadata of the source. RSA_GUID goes to the ledger. |
| `TMF_Process` Criticality, Cost, Risk, BusinessValue, Increments* | — | Dropped: assessments of one organisation, not reference content. |
| isDeleted = true | — | Element excluded. |

## Structure
Every framework hierarchy is expressed by **packages**: the parent becomes a package of the same name that holds the parent element and its children. This covers domains, process in process, function in parent function, data entity in data entity, logical component in logical component, and group in group. Associations, aggregations and compositions between business entities are not framework hierarchy but class model, so they stay connectors (see [Model classes](#model-classes)). Only two hierarchies stay relationships, because DAF 7.0 already has them:

| Source connector | DAF 7.0 |
|---|---|
| `TMF_ABEIsComposedByEntity` (model class to data entity) | `dModelClassRealizesEntity` |
| `TMF_MetricGroupMetric` (KPI to group) | `dGroupAggregatesKPI` |

In JSON and RDF exports, packages are `dafpkg:` nodes and each element is `dcterms:isPartOf` its package.

## Relationships
| Source connector | Count | DAF 7.0 |
|---|---|---|
| `TMF_ApplicationAssociatesFunction` | 948 | `dApplicationAggregatesFunction` (see [Metamodel changes](#metamodel-changes)) |
| `TMF_ProcessProducesABE`, `TMF_MakesUseOfABE` | 144 | `dBizServUsesDataEntity` |
| Association, aggregation or composition between business entities | ~2,080 | `dModelClassAssociatesModelClass`, keeping its UML ends |
| Generalization between business entities | ~1,165 | UML Generalization |
| `TMF_MetricNumenator`, `TMF_MetricDenominator` | ~600 | folded into `dMeasurementIndicator.Definition` |
| Aggregations and compositions not listed above | — | package structure |

## Model classes
`dModelClass` extends the full UML Class (tagged value `ExtendsMetaclass = true`), so the RDF export carries each business entity's class content, not only its header and tagged values.

| Source | Pack | Treatment |
|---|---|---|
| Attribute name and notes | attribute name and notes | Rewritten in DAF vocabulary, never copied. |
| Attribute bounds, visibility, static, read-only, ordered, position | the same | Carried; these are facts. |
| Attribute type | UML primitive, or the pack's rewritten Enumeration or DataType | A type that is neither is reported. |
| Attribute default | — | Dropped, as for tagged values: no invented values. |
| Operations | — | None in the source; any found are reported. |
| Generalization | `uml:superClass` | Carried. |
| Association, aggregation, composition | `dModelClassAssociatesModelClass` with `uml:Association` ends | Multiplicity, navigability and aggregation kind are carried; role names are rewritten. |

## Excluded or deferred
| What | Count | Reason |
|---|---|---|
| `TMF_Vertical` and every vertical membership | 9 elements, ~2,000 links | Dropped. |
| `TMF_CandidateRelationship` | 459 | Unconfirmed links. |
| `TMF_MetricUsesABE`, `TMF_isMeasuredBy` | 125 | No DAF target. |
| `TMF_ISC`, `TMF_IIC` | 10 | Unmapped. |
| `TMF_JSON_Schema`, `TMF_JSON_Element`, `TMF_API` and their connectors | ~2,900 elements | Deferred: close to the source schema content; a separate decision. |
| Status stereotypes (preliminary, notFullyDeveloped, likelyToChange, likelyToBeDeprecated, doNotImplement) | ~45 | Ignored. |
| Earlier DAF stereotypes on source elements (`dMeasurementIndicator`, `dCapability`, `dProduct`) | 26 | Ignored; the source stereotype and the rules above decide the type. |
| State, unused Enumeration and DataType, unstereotyped Class and Object | ~600 | Dropped. |
| BPMN, MindMap, BPSim, navigation, image, note, text, boundary | ~900 | Diagram content. |
| Everything in `Deleted*` packages | 1,101 | Excluded. |

## Metamodel changes
The pack needs two generic changes in DAF, released as **7.0.0 Beta 5** before extraction:

1. `dApplicationAggregatesFunction`: the source class moves from `dApplicationComponent` to its parent `dLogicalAppComponent`, so the relationship is valid for both, and the source multiplicity opens from `0..1` to `0..*`. In the source, 38 functions belong to more than one application.
2. `DAFBase` gains two optional properties: `pack` (the pack key) and `inspiredBy` (the concept area the element is inspired by).

The UML profile, QuickLink, JSON schema, OpenAPI and SHACL shapes are regenerated.

## Pack identity
| Item | Value |
|---|---|
| Key | `tel` |
| Name | Telecom |
| Namespace | `https://dafriontechnologies.inc/daf/pack/telecom#` |
| Version | `1.0.0` |
| Requires | DAF `>= 7.0.0 Beta 5` |
| Root package | `Telecom pack 1.0.0`, with one package per domain below it |

* `Identifier` is `tel.<kind>.<nnnn>`, for example `tel.svc.0042`. An identifier is never reused.
* The EA GUID is a UUID v5 of namespace and identifier, so a new extraction updates elements in place. The namespace must not change once the pack is released.
* Each element has `pack = tel` and `inspiredBy` set to one of: process framework, information framework, application map, business metrics, business capability map.

## Composition with other packs
* Each pack has a key and namespace reserved in `packs/registry.json`. The namespace pattern is `https://dafriontechnologies.inc/daf/pack/<name>#`. Core DAF IRIs do not change.
* A pack never changes another pack's elements or the core metamodel. Metamodel changes go into DAF first, with a version bump.
* A pack may link only to packs it declares as dependencies, by `Identifier`.
* Elements with the same name in different packs stay distinct and are never merged automatically.

## Files
| Path | Content | Published |
|---|---|---|
| `packs/telecom/MAPPING.md` | This file | yes |
| `packs/telecom/pack.json` | Manifest | yes |
| `packs/telecom/` generated XMI | The pack | yes |
| `packs/telecom/.local/ledger` | Source id to pack id | no (gitignored) |
| `packs/telecom/.local/report` | Elements not imported, with reason | no (gitignored) |
