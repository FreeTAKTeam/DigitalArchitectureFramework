# Digital Architecture Framework
## Welcome!
Welcome to the repository for the DAF MDG (Model Driven Generation) technology for Sparx Enterprise Architect. This repository contains the metamodel, the MDG technology and the resources that support modeling with DAF in Sparx EA.

**Current version: DAF 7.0** — 75 concepts, 99 relationship types and 38 enumerations. See [What's new in DAF 7.0](#whats-new-in-daf-70).

## About
The Digital Architecture Framework (DAF) is a set of modeling tools for Digital Engineering.
Its metamodel describes a modeling language that defines the notation for all elements used in the different stages of an organization's life cycle to support the concept of Digital Engineering (DE), from the requirement to the application.
![image](https://github.com/FreeTAKTeam/DigitalArchitectureFramework/assets/60719165/47281215-ca1e-45f1-8020-1885955156ab)
The DAF metamodel can be supported by frameworks in any language with good object orientation support.
An example is [DigitalPy](https://github.com/FreeTAKTeam/DigitalPy).

The full manual is [Docs/Digital Architecture Framework.docx](Docs/Digital%20Architecture%20Framework.docx) ([PDF](Docs/Digital%20Architecture%20Framework.pdf)). It describes the concepts, layers, domains and viewpoints, and lists every stereotype, tagged value, relationship, enumeration and model check.

# What's new in DAF 7.0
DAF 7.0 is a major release: it changes datatypes, renames relationships and adds concepts. Models created with DAF 6.x must be migrated. The changes are tracked in [issue #4](https://github.com/FreeTAKTeam/DigitalArchitectureFramework/issues/4).

**No invented values.** An absent value now stays unknown.
* Money, volume and duration properties use the new Quantity value type and are optional, for example `dCapability.Cost`, `dRole.#FTEs`, `dOrganizationUnit.HeadCount`, `dInitiative.EstimatedTotalCost`, `dProduct.Price` and `dMeasurementIndicator.CurrentLevel`.
* The placeholder defaults `1`, `10`, `10.00`, `100` and `5` are removed.
* `RetireDate` is a `Date`, `0..1`, on all five concepts that have it. All JSON Schema facets are optional.
* `dInitiative.InitiativeDuration` is a `Duration`, and `dInitiative.Benefit` is removed. `dRisk.likelihood` is an optional `Int32` from 1 to 100.

**New concepts and types.**
| Concept | Purpose |
|---|---|
| Quantity (`dQuantityValue`) | A value with a unit: `amount` (Decimal), `unit` (ISO 4217 currency or UCUM code), `per`, `basis`, `asOf` and `kind` (Actual, Estimate, Assumption). |
| Cost Period (`dCostPeriod`) | Spend of an initiative in one period. `dInitiative.costProfile` is an ordered list of cost periods (Capex or Opex). |
| Contract (`dContract`) | Commercial terms: `pricingBasis`, `billableUnit`, `tariff`, `effectiveFrom`/`effectiveTo` and `renewal`. Linked to products and actors. |

M3 gains the primitive types `Decimal` and `Duration` (ISO 8601, e.g. `P1M`), plus the new enumerations `dCostNature`, `dEventType`, `dEventNature` and `dQuantityKind`.

**Events, KPIs and goals.**
* `dEvent` is both a trigger and an effect, with `eventType`, `nature`, `frequency`, `likelihood`, `startDate`, `endDate`, `duration` and `owner` (a `dRole`), all optional.
* Four relationships form the flow between events and processes: `dEventTriggersProcess`, `dProcessResultsInEvent`, `dProcessFlowsToProcess` and `dEventLeadsToEvent`.
* KPIs can improve or worsen other KPIs, a goal can target KPIs (`dGoalTargetsdMeasurementIndicator`), and `dActor.Count` holds a population.

**Relationships and names.**
Every relationship end has a multiplicity, and ends that blocked realistic models are opened. Misspelled names are corrected:

| DAF 6.x | DAF 7.0 |
|---|---|
| `dApplicationComponentRealizesogicalComponent` | `dApplicationComponentRealizesLogicalComponent` |
| `dApplicationAgregatesFunction` | `dApplicationAggregatesFunction` |
| `dControllerControllsModel` | `dControllerControlsModel` |
| `dApplicationIRunsInNode` | `dApplicationRunsInNode` |
| `dRiskIRelatedToRisk` | `dRiskIsRelatedToRisk` |
| `dBusinessAreadHasCapability` | `dBusinessAreaHasCapability` |

The properties `Likehood`, `MounthPath` and `plattform` are now `likelihood`, `MountPath` and `platform`. Duplicate enumerations are merged, `MimeTypes` holds generic IANA media types, and `ArchitectureType` adds `s390x` and `ppc64le`.

**Model checks.**
* Check 009 follows the metamodel direction. Check 002 reports elements still in status Proposed.
* Check 013 accepts components whose status is not set.
* Rules that name a renamed relationship accept both the 6.x and the 7.0 name until the model is migrated.

**MDG technology.**
* UML profile and MDG technology regenerated.
* Every stereotype appears on a toolbox page, and the new stereotypes have icons and shape scripts.
* The QuickLink carries the 7.0 rules.
* The semantic model [technology/rdf/DAF-semantic-model.ttl](technology/rdf/DAF-semantic-model.ttl) (RDF/OWL with SHACL shapes) is generated from the Sparx model.

# Folder Structure
* AddIns: Sparx EA add-ins, e.g. the Relationship Manager and the OAS generator.
* API: OpenAPI description of the DAF metamodel.
* Checks: model validation rules for the EA Validator, organized by All, CIM, PIM and PSM.
* csv, excel: templates for importing model data into EA from CSV files.
* Diagrams: diagram type profiles used in the MDG.
* Docs: the DAF manual and supporting documentation of the metamodel.
* DocumentTemplates, HTML templates: templates for generating documents and HTML from EA models.
* EA searches, Queries: model searches and SQL queries.
* Icons, shapescripts: the DAF icons and the shape scripts for DAF elements.
* MatrixProfiles: relationship matrix profiles.
* Metamodel, Metamodel_json: the metamodel as XMI and as JSON schema.
* Model: the Sparx EA project that defines the metamodel used by the MDG.
* ModelWizardTemplate: model wizard templates.
* mts: MDG technology selector files.
* patterns: predefined diagram patterns for quick modeling.
* profile: the DAF UML profile.
* profile_ecore: the Ecore variant of the DAF UML profile.
* quicklinker: the QuickLink definition of the metamodel, for creating only valid connections.
* referenceData: reference data and script groups used in the MDG.
* Repository Structure: the TOGAF-based catalog structure for an enterprise repository.
* technology: the DAF MDG technology file (`DAF.xml`) and, under `rdf`, the generated semantic model.
* test model: models for testing the metamodel and the MDG.
* toolboxes: the toolbox profiles, organized by role.
* VB scripts: scripts that automate tasks within EA, such as profile and semantic model generation.

# Getting Started
To get started with this MDG:

* Download `technology/DAF.xml` from the repository or from the [releases](https://github.com/FreeTAKTeam/DigitalArchitectureFramework/releases).
* In Sparx EA, open the Resources tab, right-click MDG Technologies > Model Technologies, select Import Technology and choose `DAF.xml`.
* Read the [DAF manual](Docs/Digital%20Architecture%20Framework.pdf) for the concepts and the [MDG documentation](https://sparxsystems.com/resources/user-guides/modeling/mdg-technologies.pdf) for working with MDG technologies.

# License
This project is licensed under the EPL License. See the LICENSE file for details.
