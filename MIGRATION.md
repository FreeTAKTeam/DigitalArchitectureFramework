# Migrating models to DAF 7.0

This file records every change a DAF model must go through to reach the current version, **DAF 7.0.0 Beta 6**, and the rule for converting each one. A migrator (for example Dafrion's) should be able to apply it without guessing. Dafrion implements these rules in its `dafrion-metamodel` crate, against the pinned export `models/metamodels/daf/7.0.0-beta.4`; its README there lists, for each rule, whether it converts a value or only flags it for review.

**Principle: nothing is guessed.** A value that cannot be converted stays unknown and produces a diagnostic with the element, the property, the original value and the reason. Every diagnostic is listed in a migration report.

Renamed properties, relationships and members keep their old IRIs in the semantic model as deprecated aliases (`owl:deprecated true`, plus `owl:equivalentProperty` for properties and relationship predicates, or `skos:exactMatch` for members).

---

## Part 1: DAF 6.5.1 to 7.0 Alpha

Tracked in [issue #4](https://github.com/FreeTAKTeam/DigitalArchitectureFramework/issues/4), item 28.

| From (6.5.1) | To (7.0) | Rule |
|---|---|---|
| Money, volume and duration properties as `String`, `Int32` or `Float` | `dQuantityValue` | A number with a recognised ISO 4217 or UCUM unit becomes `amount` + `unit`. A bare number or free text becomes a diagnostic ("unit unknown"). A value equal to a removed default (`1`, `10`, `10.00`, `100`, `5`) is converted but flagged "possibly a 6.5.1 default". |
| `RetireDate` as `String` or `DateTime` | `Date` | An ISO date, or the date part of a `DateTime`. Anything else becomes a diagnostic. |
| `dInitiative.InitiativeDuration` as `String` | `Duration` | An ISO 8601 duration, or `<n> days/weeks/months/years`. Anything else becomes a diagnostic. |
| `dGoal.dAssumption` values | none in DAF | Assumptions belong to the simulation scenario, not to DAF (issue #4). Not converted; a diagnostic keeps each value for the scenario. `dGoal.AssumptionType` stays. |
| `dInitiative.Benefit` | none | Not converted. A diagnostic keeps the original value. |
| `MimeTypes` members | generic IANA types | `text/plain; charset=utf-8` becomes `text/plain`. `application/vnd.github…+json` becomes `application/json`, with a diagnostic. Other `vnd.github` types become a diagnostic. |
| Duplicate enumerations | the kept definition | Merged. |
| `dEvent.Category` | `eventType` | Only when it matches a member exactly; otherwise a diagnostic. |
| `dEvent.Owner` (text) | `owner` (`dRole`) | A diagnostic, for a person to set the role. |

Renamed in 7.0 Alpha:

| 6.5.1 | 7.0 |
|---|---|
| `dApplicationComponentRealizesogicalComponent` | `dApplicationComponentRealizesLogicalComponent` |
| `dApplicationAgregatesFunction` | `dApplicationAggregatesFunction` |
| `dControllerControllsModel` | `dControllerControlsModel` |
| `dApplicationIRunsInNode` | `dApplicationRunsInNode` |
| `dRiskIRelatedToRisk` | `dRiskIsRelatedToRisk` |
| `dBusinessAreadHasCapability` | `dBusinessAreaHasCapability` |
| `dApplicationComponentHasdContainer` | `dApplicationComponentHasContainer` |
| `dRisk.Likehood` | `dRisk.likelihood` |
| `dVolume.MounthPath` | `dVolume.MountPath` |
| `dSystem.plattform` | `dSystem.platform` |

---

## Part 2: DAF 7.0 Alpha to 7.0.0 Beta 3

Tracked in [issue #5](https://github.com/FreeTAKTeam/DigitalArchitectureFramework/issues/5). Beta 3 is a **breaking** step: several properties become elements linked by relationships.

### 2.1 Renamed properties

| 7.0 Alpha | 7.0.0 Beta 3 | Rule |
|---|---|---|
| `dRole.#FTEs` (exported as `dRole___FTEs`) | `dRole.FTEs` | Renamed; value unchanged. |
| `dCapability.CapabilityLevel` | `dCapability.HierarchyLevel` | Renamed; value unchanged. It is the level in the capability map, not a maturity. |
| `dRole.Cost` | `dRole.CostRate` | Renamed **only when the value is a rate**, i.e. it has a `basis` such as "per FTE". Otherwise see 2.2. |

### 2.2 Properties that become elements and relationships

A cost or result for a period is now an element (`dCostPeriod` or `dFinancialPeriod`) linked to its owner, so it can be traced and referenced. Each period carries `periodStart`, `periodLength` and its amounts as `dQuantityValue`.

`dInitiative.costProfile` is in the 7.0 Alpha release. `dOrganizationUnit.financials`, `dProgram.budgetProfile` and `dCapability.CostScope` only existed in pre-Beta drafts (DAF commit `ea85979`); the rules below still apply to models made with those drafts.

**Turning one quantity into one period.** A quantity with `per` (e.g. `P1Y`) and `asOf` becomes one period that ends on `asOf`: `periodLength` = `per`, `periodStart` = `asOf` − `per` + 1 day, `amount` = the quantity without `per`. Without `per`, the value is not spend per period: diagnostic. Without `asOf`, the period is unknown: diagnostic, and the value is kept in the report.

| 7.0 Alpha | 7.0.0 Beta 3 | Rule |
|---|---|---|
| `dOrganizationUnit.financials` (list of `dFinancialPeriod` values) | `dFinancialPeriod` elements + `dOrganizationUnitReportsFinancialPeriod` | One element per list item, with its fields unchanged, linked from the organisation unit. |
| `dInitiative.costProfile` (list of `dCostPeriod` values) | `dCostPeriod` elements + `dInitiativeHasCostPeriod` | One element per list item, linked from the initiative. |
| `dProgram.budgetProfile` (list of `dCostPeriod` values) | `dCostPeriod` elements + `dProgramHasBudgetPeriod` | One element per list item, linked from the program. These are caps, never included in a financial period. |
| `dApplicationComponent.Cost` | `dCostPeriod` element + `dApplicationComponentHasCostPeriod` | One period, by the rule above. `costNature` stays absent unless the source says Capex or Opex. |
| `dRole.Cost` without `basis` (a total, not a rate) | `dCostPeriod` element + `dRoleHasCostPeriod` | One period, by the rule above. |
| `dCapability.Cost` with `CostScope` = `Direct` | `dCostPeriod` element + `dCapabilityHasCostPeriod` | One period, by the rule above. |
| `dCapability.Cost` with `CostScope` = `Aggregated` or absent | none | **Not converted**, to avoid counting the cost of linked roles and applications twice. A diagnostic keeps the value; the full cost of a capability is now derived from the cost periods of its linked roles and applications. |

**Including costs in statements.** A cost period may be included in the financial period of the organisation unit whose books it lands in (`dFinancialPeriodIncludesCostPeriod`). The migration does not create these links, because which unit pays is not recorded in 7.0 Alpha. Add them afterwards. In Beta 3, Opex landed in `operatingExpense` and Capex in the new `capitalExpenditure`; Beta 4 refines this by income-statement line (Part 3).

### 2.3 Type changes

| Property | 7.0 Alpha | 7.0.0 Beta 3 | Rule |
|---|---|---|---|
| `dRisk.Severity` | `String`, default `50` | `Int32` 1–100, optional | A whole number from 1 to 100. Anything else: diagnostic. The value `50` is flagged "possibly a default". |
| `dPhysicalService.NextStandardReviewDate` | `String` | `Date` | An ISO date. Anything else: diagnostic. |
| `dRole.DegreeOfUtilisation` | `String` | `dQuantityValue`, unit `%` | `"88 %"` or `"88%"` becomes 88 %. A bare number from 0 to 1 (e.g. `"0.88"`) becomes 88 % with a diagnostic "read as a fraction"; a bare number above 1 becomes that many % with a diagnostic. Anything else: diagnostic. |
| `dContract.pricingBasis` | `String` | `dPricingBasis` | Text that names a member (`PerUnit`, `PerPartyPerPeriod`, `FlatFee`, `Tiered`) maps to it: "per transaction" → `PerUnit`, "per subscriber/policy per month" → `PerPartyPerPeriod`, "flat fee" → `FlatFee`. Other text becomes `Other`, copied into `Description`, with a diagnostic. |
| `dAPIOperation.deprecated`, `dAPIParameter.allowEmptyValue`, `dAPIParameter.required`, `dAPIResponse.default`, `exclusiveminimum`, `exclusivemaximum` and `uniqueItems` on `dJSON_SchemaSubSet` and `dJSON_Type` | `String` | `Boolean` | `true`/`false` (any case), `yes`/`no`, `1`/`0`. Anything else: diagnostic. |
| `maxlength`, `minlength`, `maxItems`, `minItems`, `maxProperties`, `minProperties` on the JSON types | `String` | `Int32` | A whole number. Anything else: diagnostic. |
| `minimum`, `maximum`, `multipleof` on the JSON types | `String` (`dJSON_Type.minimum`: `Int32`) | `Decimal` | A number. Anything else: diagnostic. |
| `dLocation.Country` | `String` | `String`, ISO 3166-1 alpha-3 | A valid alpha-3 code stays. A recognised country name or alpha-2 code becomes alpha-3 (e.g. `IT` → `ITA`) with a diagnostic. Anything else: diagnostic. |

### 2.4 Multiplicities and defaults

* Only 28 properties stay required; all others became `0..1` or `0..*`. No value has to be removed.
* `dDecision.RelatedDecisions` goes from `1..*` to `0..*`; the target end of `dApplicationComponentRealizesLogicalComponent` goes from `0..1` to `0..*`.
* `dCapability.Increments`, `IncrementsToBe`, `IncrementVertical` and `IncrementSupplyChain` are optional: absent means not assessed.
* Defaults are removed from all optional properties. A stored value that equals a removed default is kept but flagged "possibly a default", for a person to confirm. The removed defaults are: `50` on the 1–100 scores (`BizSatisfaction`, `ITSatisfaction`, `BizCriticality`, `Criticality`, `Risk`, `Priority`, `ability to Implement`, `Severity`); `Retain` (`InvestmentStrategy`); `Custom` (`ApplicationType`); `unknown` (`ProcessCriticality`); `Not Set` (`ActorType`); `Low` (`BusinessValue`); `1` (`HierarchyLevel`); `AMD64` (`ArchitectureType`); `Medium` and `I` on `dStakeholder`; `None` and `Initial` on the `Increment*` properties; `unspecified` (`dQuantityValue.kind`); `8` (`EstimatedEffort`); `myName, Analyst`, `aName, Client` and `none` on authors, proofreaders and `Responsible`; and the generator settings on `dModelClass` and `dValue`.

### 2.5 Deprecated, not removed

| Property | Use instead |
|---|---|
| `dInitiative.RelatedProgram` | the path `dProgram` → `dGrowthPackage` → `dInitiative` |
| `dInitiative.Impacted Capability` | `dInitiativeIncreasesMaturityOf` |
| `dCapability.CostScope` | nothing for new models: `dCapability.Cost` is removed. A migrator still reads it, to decide whether an old `Cost` is converted (see 2.2). |

### 2.6 New, no migration needed

`dObjective.Value_Goal`, `dInitiative.actualStartDate` and `actualFinishDate`, `dFinancialPeriod.capitalExpenditure`; the relationships `dRoleStaffsService`, `dRoleMaintainsApplication`, `dProcessControlsProcess`, `dInitiativeDeploysApplication`, `dInitiativeRetiresApplication`, `dInitiativeChangesProcess`, `dInitiativeChangesLogicalComponent` and `dFinancialPeriodIncludesCostPeriod`; the enumerations `dPricingBasis` and `dCostScope`.

Meaning changes without a data change: `dGoal.Value_Goal` is the change from `Value_amount`, not a level; a goal's deadline is the latest `finishDate` of its objectives; `dRoleConsumesService` means the role uses the service's output, and the roles that do its work move to `dRoleStaffsService` (a person must decide; the migration flags each `dRoleConsumesService` link for review).

---

## Part 3: DAF 7.0.0 Beta 3 to 7.0.0 Beta 4

Beta 4 adds revenue, the income-statement line of each cost, assets and depreciation. It is **breaking** only in one rule: which statement line an included cost is checked against. It follows a review of a driver-based financial model (EuroCom/Expedibox: revenue streams, cost of goods sold per stream, SG&A, Capex and straight-line depreciation, P&L, cash flow and DCF).

### 3.1 Changed rules and meanings

| Element | Beta 3 | Beta 4 | Rule |
|---|---|---|---|
| `dCostPeriod` | `costNature` only (Capex/Opex) | adds `costFunction` (`dCostFunction`: CostOfRevenue, SellingGeneralAdmin, ResearchDevelopment) | Set `costFunction` when the source names the line: "COGS", "cost of sales", "cost of revenue" → `CostOfRevenue`; "SG&A", "opex", "overhead", "maintenance" → `SellingGeneralAdmin`; "R&D" → `ResearchDevelopment`. Otherwise leave it absent. A cost period with `costNature` Opex that is included in a financial period and has no `costFunction` gets a diagnostic, because its statement line cannot be checked. Never set `costFunction` on Capex. |
| Inclusion check on `dFinancialPeriod` | Opex ≤ `operatingExpense`, Capex ≤ `capitalExpenditure` | by line: CostOfRevenue ≤ `costOfRevenue`; SellingGeneralAdmin and ResearchDevelopment ≤ `operatingExpense`; Capex ≤ `capitalExpenditure` | No data change; checks follow `costFunction`. |
| `dFinancialPeriod.operatingExpense` | all other operating cost | the same, **excluding depreciation** | When the source states a depreciation figure that was inside operating expense, move it to the new `depreciation` line and reduce `operatingExpense` by it. When it is unknown whether depreciation was included, keep the value and add a diagnostic. |
| `dFinancialPeriod` wording | "a cash view" | holds income-statement lines plus the cash line `capitalExpenditure`; subtotals (gross margin, EBITDA, EBIT, net income, free cash flow) are derived and never stored | Remove stored subtotals, if a twin carries any, after checking they match the derived value; a mismatch is a diagnostic. |
| `dContract.tariff` | `0..1` | `0..*`: price components, each with its own `basis` | An existing tariff becomes a list of one. No conversion: tariff was already a single quantity, so a multi-part price could not be stored before and has to be entered by hand. |

### 3.2 New, no migration needed

* `dRevenuePeriod` (revenue of a product or contract in one period), with `dProductHasRevenuePeriod`, `dContractHasRevenuePeriod` and `dFinancialPeriodIncludesRevenuePeriod`. Revenue per product or contract that a twin kept outside DAF can be loaded as revenue periods; the rule for one quantity → one period in 2.2 applies.
* `dProductHasCostPeriod` (direct costs of a product, e.g. hardware for resale) and `dResourceHasCostPeriod` (purchase and upkeep of a resource, e.g. an owned fleet).
* On `dResource` and `dApplicationComponent`: `inServiceDate`, `usefulLife` (Duration) and `depreciationMethod` (`dDepreciationMethod`: StraightLine, DecliningBalance). The depreciation schedule is derived from the Capex cost periods and these properties and is not stored.
* On `dFinancialPeriod`: `depreciation` and `interestExpense`.

---

## Part 4: DAF 7.0.0 Beta 4 to 7.0.0 Beta 5

Beta 5 prepares DAF for industry packs (see [packs/telecom/MAPPING.md](packs/telecom/MAPPING.md)). It is **not breaking**: every Beta 4 model is a valid Beta 5 model.

### 4.1 Changed rules and meanings

| Element | Beta 4 | Beta 5 | Rule |
|---|---|---|---|
| `dApplicationAggregatesFunction` | from `dApplicationComponent`; a function is part of `0..1` applications | from `dLogicalAppComponent`, which `dApplicationComponent` specialises; a function is part of `0..*` applications | No data change: every existing link stays valid. In EA the QuickLinker offers the link from logical components, like the other relationships that start from `dLogicalAppComponent`; it can still be drawn from the toolbox. |

### 4.2 New, no migration needed

* On `DAFBase`, so on every concept: `pack` (the key of the industry pack that supplied the element, e.g. `tel`) and `inspiredBy` (the concept area a pack element is inspired by). Both are optional and stay absent for elements authored in the model itself.

---

## Part 5: DAF 7.0.0 Beta 5 to 7.0.0 Beta 6

Beta 6 adds business rules and lets model classes carry their full UML content. It is **not breaking**: every Beta 5 model is a valid Beta 6 model.

### 5.1 New, no migration needed

* `dRule` (Rule): a business rule, a precise condition or constraint enforced at one point in an application. It is a stereotyped UML operation, with visibility package, of the `dController` that enforces it; the controller is the rule set. Its properties are `RuleKind` (`dRuleKind`: Production, Integrity, Derivation, Reaction), `Statement` (the rule in plain language), `SourceEvidence` (where it was found in existing code) and `Certainty` (`dRuleCertainty`: Explicit, Inferred). Its inputs and result are the operation's own parameters and return type.
* `dModelClass` extends the UML Class (`ExtendsMetaclass = true`): in the semantic model it is a subclass of `uml:Class` from `technology/rdf/DAF-uml.ttl`, so its instances keep their attributes, operations, generalizations and association ends.

---

## Files still on old names

The JSON schema (`Metamodel_json/DAFSchema.json`) and the OpenAPI description (`API/`) are generated from the Beta 6 semantic model; their property and relationship names are the metamodel's, so API clients built on the older OAS (camelCase names such as `fteCount`) must follow the renames above. These artefacts are not yet regenerated for Beta 5 and still use names or types changed above: `Metamodel_json/DigitalArchitectureFramework.json` (an older draft-04 export), `Metamodel/DAF_Metamodel.xmi`, `Queries/*.sql` (they read the `Cost` tag), `VB scripts/DAF_model_RDF_Exporter.vbs` (`Cost` on applications, capabilities and roles), the CSV templates in `csv/` and `excel/`, and the test model.
