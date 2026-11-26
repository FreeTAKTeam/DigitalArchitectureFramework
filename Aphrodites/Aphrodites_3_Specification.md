# Aphrodites 3.0: the specification in seven steps

**Status:** version for testing, 26 November 2026. Many of its concepts are new and have not been tried. No decision in it is final: each one is confirmed or changed by what testing shows. The text is not extended before the first tests.

**Licence:** Creative Commons Attribution, crediting both authors of the original Aphrodite specification.

## 1. What Aphrodites is

Aphrodites says what a framework must provide so that an application generated from a DAF 7 model runs on it and stays connected to that model. The connection between the running application and the model is the digital thread. It is the main addition of version 3.0.

| Reader | Uses this text to |
|---|---|
| A framework builder. DigitalRust is the first | Know what to build |
| A generator writer | Know what generated code may rely on |
| A reviewer | Judge whether a framework or a generated application fits |

Version 3.0 covers server applications only.

| Version | Its framework |
|---|---|
| 1 | wCMF, in PHP. The first version of Aphrodites was written with it: the original specification describes the architecture of wCMF, and the author of wCMF is one of its two authors |
| 2 | DigitalPy, in Python. It implements Aphrodites 2.0, which added components, services and access control |
| 3 | DigitalRust, in Rust. It will be the only framework of this text, and it is not started |

wCMF and DigitalPy were built for their own versions and are not expected to comply with this one. What changed from one version to the next is in `Aphrodites_3_Gap_Report_v1_v2.md`.

## 2. How to read it

The specification is seven steps. Each step can be built and shown before the next one is started.

| Step | Name | What you can show when it is done | Level reached |
|---|---|---|---|
| 1 | Run | An application built on the framework stores and serves its data | |
| 2 | Operate | Components come and go while the framework runs; flows between them, events, settings and access work | C |
| 3 | Identify | A running component says which model and which build it is | |
| 4 | Report | The twin sees what the component did | T1 |
| 5 | Change a setting | The twin changes a setting of a running component | |
| 6 | Change a rule | The twin changes a business rule of a running component | T2 |
| 7 | Replace | A component is replaced by another version and keeps its data; the twin can order it | T3 |

A framework states the highest step it has reached. The levels C, T1, T2 and T3 are the names used in a component's manifest.

Each step has four parts: what you can show, the rules, how a reviewer checks them, and what is settled or still an assumption.

**How it is tested.** One step at a time. Build the step on a framework, run its checks, correct this text from what was learned, and only then start the next step.

**The rules are short on purpose.** A rule says what must be true, not how to build it. What no rule mentions is left to the framework.

**Convention over configuration.** This is a key principle of DAF and of Aphrodites. What the model already says needs no code and no setting: the framework applies it. A movie owns one poster and needs a director, so creating a movie creates its poster and gives it a minimal default director. Where the model is silent, a default applies, and the framework says which.

**Information has an owner and an identity of its own.** *The idea is the owner's, from the Reticulum Distributed Objects (RDO) specification. Rules 2.1 and 2.14 state it between components. They were written on 26 November 2026. The policy-inquiry reference shows them; it is approved and not built yet.* In DAF a component is a container: it encapsulates information and behaviour. Until now the container was also a border. What is inside is hidden, and between two components only operations and events are visible. That border did two jobs at once, and RDO separates them. *Who may change* a piece of information stays with one owner. *Who may know of it and refer to it* is open, because the information is identified by itself and not by the component or the machine that holds it.

A component then owns some information, keeps copies of other information, and refers to the rest. A relationship can lead from the information of one component to the information of another. DAF is built for this: a model class is an element of its own, not a part of a component, and a component reaches it by a path through its functions and controllers (section 6). An impact analysis can follow that path from a component to the information, and on to the next component.

This text takes over the idea and not the network: RDO is the form the idea has on Reticulum. In the rules it reads as follows:

| Idea | In this text |
|---|---|
| An identity that does not depend on where the information is | Rules 1.1 and 3.5. Another component refers to an entity by its owner and its identifier (2.14) |
| One owner, and only the owner changes it | Rule 2.1. On the thread: the twin owns the model and what is approved, the component owns what runs and what it observed (5.7) |
| The others copy or ask | Between components, a component refers to an entity and asks its owner (2.1 and 2.14). On the thread, a report is the component's statement, and the twin keeps a copy of it (step 4). A change is the twin's approved state, and the component takes it over or refuses it (step 5) |
| Delivered is not the same as applied or recorded | Rules 2.10, 4.5 and 5.5 |

One part is still missing in the rules: a copy that says what it is a copy of (open decision 11). Two words differ in RDO: its *twin* is any owner, and its *property* is a value here.

**Two outcomes when a rule is broken.** Each rule that can be broken says which one applies:

| Outcome | Meaning | Used where |
|---|---|---|
| Refused | The thing does not happen, and whoever asked is told why | Carrying on would do harm: bad input, a component that cannot be installed, a change from the twin that fails a check |
| Warned | The framework records the problem where an operator can see it, and carries on | Stopping would hurt the business more than the problem does: a missing binding, a report that cannot be delivered |

**Settled and assumption.** Much of this text has not been tried in an implementation yet.

- *Settled* means taken from something that works today (the original specification, the Digital Engineering book, DAF 7, DigitalPy, an existing twin host) or decided by the owner.
- *Assumption* means designed on paper. Expect it to be rewritten after the first implementation.

Steps 1 to 4 rest mostly on settled ground. Steps 5 to 7 are almost entirely assumption, because no twin host can send a change to an application today. They are kept short for that reason.

## 3. Words

| Word | Meaning |
|---|---|
| Model | The DAF 7 model held in the twin |
| Twin host | The system that holds the model and receives reports. One exists today and is not public; this text calls it the existing twin host |
| Framework | What this text specifies: the part that is the same for every application |
| Component | The unit that is generated, deployed and connected to the model |
| Owner | The one component that may change an entity. Which component that is, is calculated from the model (section 6) |
| Generated file | A file the generator owns and replaces at every run |
| Hand-written file | A file a person owns. The generator never changes it |
| Entity type, value, relationship | The data of an application, as the model describes it |
| Operation, method | Something a component can be asked to do, and the code that does it. An operation belongs to a controller |
| Interface | The form in which a caller reaches the operations, such as OpenAPI, AsyncAPI or MCP. It is a channel, and holds none of the application's logic or data |
| Action | A sequence of methods, inside one controller or from one controller to another |
| Action key | A one-way link from one controller to another. It says which method of the target controller runs when a named action happens in a named context |
| Rule | One business rule: a decision, a calculation or a restriction that belongs to the business |
| Manifest | The one document that describes a component |
| Binding key | A short name, unique in a manifest, for something the component reports about or lets the twin change |
| Report | What a running component sends to the twin host. The schema file calls it evidence |
| Change package | One approved change, sent from the twin host to a component |

## 4. Four kinds of logic

A model holds logic of four kinds. Each has its own place in the model and in the application.

| Kind | What it is | In DAF 7 | In the application | Step |
|---|---|---|---|---|
| Structure, also called structural behaviour | What follows from how the data is built. A movie has one poster, and the poster goes when the movie goes | Classes, values and relationships | The framework applies it, by convention. No code is written for it | 1 |
| Rule | A production rule: if this holds, change that. It runs inside a controller | `dRule`, an operation of a `dController` | The content of the rule, which the twin can change | 1 and 6 |
| Action | The sequence of methods inside a controller, or from one controller to another | `dAction`; between controllers, the action keys (`dActionKey`) | Generated where the model gives the sequence, hand-written otherwise | 1 |
| Application flow | The path between applications or components, with its decision points | Action keys (`dActionKey`) between their controllers. A key can stand for a physical service endpoint | Generated from the action keys | 2 |

In the five layers of section 5, structure is knowledge, although it is called a behaviour, and the other three kinds are intelligence.

## 5. Who supplies what

Every part of an application has three sides. The framework supplies the part that is the same everywhere (the frozen spots). The application supplies the part that differs (the hot spots), generated from the model or written by hand. The thread is what connects the part to the model.

| Part | The framework supplies | The application supplies | The thread |
|---|---|---|---|
| Data | Identity, checks in memory, how relationships behave, everything an entity needs created by default | The entity types, generated | Calculated by the twin from the model |
| Storage | The storage operations | The mapping to the store, generated | |
| Operations | Dispatch, the check of the input, how a request ends | Methods: generated for create, read, update and delete, hand-written otherwise | The outcomes of an operation are counted, and each count is a measure with a binding key |
| Rules | Evaluation, and the limits on what a rule may touch | The content of each rule | Rules get binding keys; their content can be changed from the twin |
| Service | The adapters to the networks and the interfaces it offers, with their descriptions | The endpoints, generated | |
| Components | Install and remove; replace by another version (step 7) | The manifest, generated | The binding part of the manifest |
| Events | Publish and subscribe, inside one framework and between machines | The event types, generated | |
| Settings and access | Loading settings, the access filter | The declared settings and permissions, generated | Settings the twin may change |

**The same parts in five layers.** An application can also be read as five layers. This is an aid for reading and not a rule.

| Layer | What it is | In an application | Where |
|---|---|---|---|
| Experience | How a person or a system interacts with it | The interfaces through which a caller reaches the application, such as OpenAPI, AsyncAPI and MCP. An interface is a channel: it is kept apart from the intelligence and the knowledge it gives access to (rule 1.20). Views are left out of version 3.0 | Step 1, Service |
| Intelligence | The ability to execute behaviour over knowledge | The behaviour: operations with their methods, rules, actions, and the flow between components | Step 1, Operations and actions, and Rules; step 2, Application flow; step 6 |
| Knowledge | The domain | Entity types, values and relationships, and what follows from how they are built. Also what connects the application to the model: the binding and the reports | Step 1, Data; step 2, Information across components; steps 3 and 4 |
| Compute | Executing and persisting | The framework: storage, dispatch, the evaluation of rules, components, events, settings and access | Step 1, Storage; step 2, Components, Events, and Settings and access; step 7 |
| Fabric | Connecting every node | The networks a framework offers, and events between machines | Rules 1.21, 2.9 and 2.10 |

The definition of intelligence is the owner's. In a twin host the knowledge is the twin, and the behaviour over it is query, analysis and simulation. In an application the knowledge is its domain, and the behaviour over it is what its controllers do.

The application supplies knowledge and intelligence, and the framework supplies compute and fabric. The thread passes through the layers in both directions. A report carries knowledge up to the twin (steps 3 and 4). A change comes down: to a setting or a rule (steps 5 and 6), or to the whole component (step 7).

## 6. The generator

The generator is not part of the framework. It has its own rules and its own proof.

DAF 7 defines these, and a generator reads them:

| In the application | In DAF 7 |
|---|---|
| Entity type, with inheritance and abstract types | `dModelClass`, a UML class |
| Value | `dValue`, an attribute of the class: name, type, bounds, read-only, restrictions |
| Value reference | `dValueRef` |
| Relationship | `dModelClassAssociatesModelClass`, a UML association. Each end has a kind, a multiplicity and a direction. Role names are not in DAF 7.0.0 Beta 7. They are prepared for a later release |
| Names in a relational store | `table_name`, `pk_name`, `column_name`, `db_data_type` |
| Controller | `dController` |
| Operation | An operation of a controller that is not a rule |
| Action, a sequence of methods | `dAction`. From one controller to another: `dActionKey`, a one-way dependency with the properties `action`, `context`, `method`, `config` and `decorator` |
| Rule | `dRule`, an operation of a controller, with `Statement`, `RuleKind`, `SourceEvidence` and `Certainty` |
| Component | `dApplicationComponent` |
| The controllers and entity types of a component | A path, not one relationship. The component aggregates functions, itself or through the logical component it realizes. A controller implements a function, and controls model classes |
| The owner of an entity type | Calculated too. The owner is the component that works on the type, by the path above, and also offers it through a service: component, physical service, API, JSON schema, model class. A component that only works on it holds a reference to it (rule 2.14), or a copy |
| Service and API | `dPhysicalService`, with its protocol and whether it answers at once or later; `dAPI`, `dAPIOperation` |
| Event | `dEvent` |
| Measure | `dMeasurementIndicator` |
| What the component is meant to meet | `dRequirement`, `dFeature`, `dBusinessUseCase`. Also a path: a controller implements a use case, the use case realizes a feature, and the feature satisfies a requirement |

**DAF often states a dependency indirectly.** It is then not one relationship but a path of several, and whoever reads the model follows the path. Only the path that is meant counts: many other paths connect the same two elements by accident, for example through a role or a cost.

Not all of this reaches a generator today:

- An export from Enterprise Architect carries the content of model classes only. The operations of a controller and the restrictions of a value do not arrive.
- The generation model in use today holds no relationships and no inheritance yet.
- `dActionKey` has its definition and its five properties in the profile and in the semantic model since DAF 7.0.0 Beta 7. That they reach a generator has not been shown.
- DAF 7 has no single relationship that says which controller publishes or handles an event, which business outcomes an operation has, what a single setting is, or who may perform an operation. These four were listed before indirect paths were looked at. They need a second look.

Until the model and the tools can supply these, they come from the generator's approved input (rule G1) and never from a guess.

| # | Rule |
|---|---|
| G1 | A generator works from one approved input. If that input lacks something the generator needs, it stops and names what is missing. It makes nothing up. |
| G2 | Every produced file is either generated or hand-written. A generated file is replaced at every run and is not edited by hand. A hand-written file is never touched by the generator. Where hand-written code is still missing, the application says "not implemented". It never silently does nothing. |
| G3 | For create, read, update and delete, the generator produces the complete method. |
| G4 | The same input, generator version and options give the same generated files. |
| G5 | The generator produces one permission for each public operation. |
| G6 | The generator writes the binding of the manifest (step 3) from the same approved input as the code. It records that input's digest and the model revision. |

An AI may write a hand-written part, and a person reviews it. Because of G4, no AI takes part in producing a generated file.

**The generator's proof:** it produces Filmology from that application's approved input, and the result passes the Filmology scenario on a framework at step 1. That approved input is not written yet, so this proof cannot be run today.

**How a reviewer checks:**

1. Generate twice. The generated files are identical. That includes the manifest, before the build adds its digest.
2. Edit a hand-written file, change the model, generate again. The hand-written file is unchanged and the application builds.
3. Give the generator a value without a type. It stops and names the value.

## 7. Step 1: Run

**What you can show:** the Filmology application, built on the framework, passes its scenario (`Aphrodites_3_Reference_Filmology.md`). For this step it does not matter whether the application was generated or written by hand.

A sensible order inside this step: data, storage, operations and the service first; then rules.

### Rules

**Data**

| # | Rule |
|---|---|
| 1.1 | Every entity has an identifier from the moment it is constructed, and the identifier never changes. |
| 1.2 | A value has a name and a type. It accepts only data of that type that passes its restrictions. A read-only value is set at construction and never again. A value reference shows a value of a related entity and cannot be set. |
| 1.3 | The checks the model declares for an entity are its types, its restrictions and how many related entities it needs. They are made in memory, when the entity is constructed or changed, not when it is saved. A refused change leaves the entity as it was and says which check refused it. |
| 1.4 | A relationship keeps what the model says: its kind, how many entities each end allows, the role name of each end, and the directions it can be followed in. Going beyond any of these is refused. |
| 1.5 | The three kinds of relationship behave as in the table below. |
| 1.6 | An entity type has every value and relationship of the types it extends. An abstract type cannot be constructed. |
| 1.7 | When an entity is constructed, everything it needs is constructed with it. A child it must own is created with default values. A related entity that exists on its own, such as a movie's director, starts as a minimal default one. Nothing is refused for being left out. |

| Kind | Deleting the parent deletes its children | A child can be created through the parent | An existing entity can be attached |
|---|---|---|---|
| Composition | Yes | Yes | No |
| Aggregation | No | Yes | Yes |
| Association | No | No | Yes |

Completing what was created by default is the application's job, not the framework's. The application offers to add an element where the entity owns it (composition), and to select an existing one where it does not (aggregation).

**Storage**

| # | Rule |
|---|---|
| 1.8 | For every stored entity type the framework provides, without hand-written code: create, read by identifier, find by the values of the entity or of a related entity, update and delete. For every relationship it provides: attach, detach and list. |
| 1.9 | Everything changed while one request is handled is stored together or not at all. |
| 1.10 | A store that fails or is busy is never reported as "not found" or as an empty result. |
| 1.11 | The application reaches the store only through these operations, so that one store can be exchanged for another. |

**Operations and actions**

| # | Rule |
|---|---|
| 1.12 | An operation has a name that is unique in its component, typed input and output, and exactly one method. |
| 1.13 | The input is checked against the declared types before the method runs. Input that does not fit is refused. |
| 1.14 | Every request ends in exactly one of: a result; a refusal as invalid input, not allowed or unknown operation; or a failure. "Not found" is a result, not a failure. A failure undoes what the request changed, and its answer contains no stored data and no technical detail. |
| 1.15 | An action is a sequence of methods, inside one controller or from one controller to the next. Between controllers it follows the model's action keys: when the named action happens in the named context, the named method of the target controller runs. An empty action or context fits any. An empty method means the method with the action's name. |

**Rules**

| # | Rule |
|---|---|
| 1.16 | A rule is a named unit with a statement in plain language, the entities it reads and the entities it may change. It changes nothing else. |
| 1.17 | A rule never changes the structures of the model. It can set a movie's color. It cannot change what a movie is: its values, their types or its relationships. |
| 1.18 | A framework supports production rules: "if this holds, change that". The condition can use the values of the entities the rule reads, also those reached through a relationship. The consequence can set a value. Integrity, derivation and reaction rules are optional. |
| 1.19 | What a rule changes is checked like any other change (1.3). If one change is refused, none of that rule's changes is kept. |

How the content of a rule is written is the framework's choice: a table, an expression, a set of parameters. All the rules of one component are written the same way. In DAF 7 a rule's `Statement` is the plain-language text from which a person or an AI writes that content.

**Service**

| # | Rule |
|---|---|
| 1.20 | A service is a channel and nothing more. It translates between an interface, such as OpenAPI or MCP, and the operations. It holds no application logic, no rules and no data of its own. Whichever interface is used, the same operation runs and the same entities are reached. |
| 1.21 | No kind of network is prescribed, and a framework can use several at the same time. A service can answer a request at once, as over HTTP, or exchange messages, as over a mesh network such as Reticulum. Application code does not know or choose which network carries a request. The framework states which networks it offers. Each service has a description a machine can read and that agrees with the model, such as OpenAPI for requests, AsyncAPI for messages and MCP for agents. |
| 1.22 | Each way a request can end (1.14) can be told apart in the answer on the network. |

### How a reviewer checks

1. Run the 20-step Filmology scenario. Every step gives the expected result.
2. Construct an abstract type, and set a read-only value after construction. Both are refused.
3. Make the store unavailable and read an entity. The answer is a failure, not "not found".
4. Send a request with input of the wrong type. It is refused as invalid input and the method does not run.
5. If the framework offers more than one interface, call one operation through two of them. The same method runs, and both give the same result.

**The verdict.** A framework is compliant with step 1 when every rule of this step is shown. One rule that fails means not compliant. `Aphrodites_3_Step1_Certification.md` says, rule by rule, what shows it. The same sheet records what the frameworks of versions 1 and 2 do, without a verdict: they were built for their own versions.

### Settled and assumption

- **Settled:** data, relationships, the kinds of rule, operations and their dispatch, and action keys as the owner defines them. They come from the original specification, the book and DigitalPy. The owner's decisions: checking in memory; a rule never changes a data structure; an entity is created with defaults for everything it needs; no kind of network is prescribed, and several are used at once, as Reticulum does; an interface is a channel, kept apart from the intelligence and the knowledge it gives access to, and MCP is one more interface, like OpenAPI (26 November 2026).
- **Assumption:** storing a request's changes together. How rule content is written.

## 8. Step 2: Operate

**What you can show:** a second component is installed and removed while the first keeps answering requests, and a flow passes from one component to the other. The policy-inquiry application shows this beside the customer-inquiry application: a policy names its holder, a customer that the other component owns (`Aphrodites_3_Reference_Policy_Inquiry.md`).

### Rules

**Components**

| # | Rule |
|---|---|
| 2.1 | A component is reachable only through its public operations and the events it publishes. Its rules and internal operations are not reachable from another component. Its data has one owner, the component itself. Another component can refer to one of its entities (2.14), and reads or changes it only through the owner's public operations. |
| 2.2 | A component has one manifest. Its component part gives an identifier that stays the same across versions, a name, a version, the specification version and level the component needs, and its public operations. A component whose component part is invalid, or which needs more than the framework offers, is refused. |
| 2.3 | The framework can install and remove a component while the other components keep serving requests. It can list its components with their version and state. |

Replacing a component by another version is step 7.

**Application flow**

| # | Rule |
|---|---|
| 2.4 | The flow between components, and between applications, follows action keys, as it does between controllers (1.15). The action that happened and its context decide which key applies: that is the decision point. A key that leads into another component leads to one of its public operations. |
| 2.5 | An action key can stand for a physical service endpoint. Its `decorator` says that the resulting operation is offered as a service, for example over REST. The flow then goes over the network (1.21) to wherever the target runs. |

**Events**

| # | Rule |
|---|---|
| 2.6 | A component can publish an event, and others subscribe by event type. The publisher does not know its subscribers. |
| 2.7 | An event published while a request is handled is delivered only if that request's changes were stored. |
| 2.8 | A subscriber that fails does not fail the publisher or the other subscribers. The framework warns. |
| 2.9 | An event can travel to another machine, over any network the framework offers (1.21). Whatever the network, the receiver learns five things: the event's identifier, its source, its type, its time and its data. A network may supply some of them itself. LXMF supplies the identifier, the source and the time, and proves the source by a signature; the type and the data travel in its fields. Where the network has room, the event travels as a CloudEvents event. |
| 2.10 | Between machines an event arrives at least once, in no promised order, and possibly much later: a mesh network can hold a message until the receiver is in reach again. A repeat carries the same source and identifier, so that the receiver can recognise it. An acknowledgement from the network says that the event was delivered, not that it was processed. The framework describes its events in a form a machine can read, such as AsyncAPI. |

Keep events small. On a Reticulum network one LXMF message in a single packet carries about 290 bytes of content. A larger event still arrives, but it needs a connection and many packets. An event written as CloudEvents JSON is larger than that.

**Settings and access**

| # | Rule |
|---|---|
| 2.11 | A setting has a name, a type and a default. A value of the wrong type is refused when the component starts, not when the setting is first used. |
| 2.12 | A secret setting never appears in logs, answers or reports. |
| 2.13 | Before a method runs, the framework asks an access filter whether the caller may perform the operation. If not, the request is refused as not allowed and the method does not run. As long as no permission is configured, every public operation is allowed, and the framework says that the component is unrestricted. |

Who holds a permission is a matter for the deployment. The permissions themselves come from the generator, one for each public operation (rule G5).

**Information across components**

| # | Rule |
|---|---|
| 2.14 | A relationship can lead to an entity that another component owns. The component that holds the relationship stores two things about that entity: the identifier of the owning component (2.2) and the identifier of the entity (1.1). It stores none of the entity's values as its own. When the owner cannot be reached, following the relationship is a failure, never "not found" and never an empty result (1.10). |

Such a relationship keeps what the model says, like any other (1.4). Because only the owner changes its entities, the other component attaches and detaches an entity that exists. To have one created or deleted, it asks the owner through a public operation.

### How a reviewer checks

1. With one component serving requests, install a second one and remove it. The first never stops answering.
2. Install a component whose manifest has no version. It is refused.
3. Follow an action key from a controller of one component to a public operation of another. The target method runs. With another action, another key applies or none does.
4. Publish an event inside a request that then fails. No subscriber receives it.
5. Publish an event on one machine with a subscriber on another. It arrives with the same identifier, source, type, time and data. Deliver it a second time: the receiver recognises the repeat.
6. With no permission configured, call a public operation. It is allowed, and the framework lists the component as unrestricted. Give the permission to one caller and call as another: the answer is "not allowed" and the method did not run.
7. Give a setting a value of the wrong type. The component refuses to start. List the settings: a secret is not shown.
8. Run the scenario of the policy-inquiry reference. A policy stores the owner and the identifier of its holder, and no value of the customer. A change made at the owner is seen through the relationship. With the owner removed, the answer is a failure, not "not found".

### Settled and assumption

- **Settled:** components installed at run time, the manifest, publish and subscribe, and the access filter come from DigitalPy and the book. The owner's decisions: runtime install is part of 3.0; application flow follows action keys, which can stand for service endpoints; with nothing configured a component is open and says so; events between machines as rules 2.9 and 2.10 state them; information has one owner, and other components refer to it (section 2).
- **Assumption:** the wording of rule 2.14, and its last sentence on an owner that cannot be reached. The policy-inquiry reference shows the rule, but it is not built, and open decision 11 lists what is not settled. When exactly an event is delivered. Rules 2.9 and 2.10 were checked against the Reticulum manual and the LXMF code of Fabric, not against a running network. How a generator learns a key's `decorator`, which is not yet in the profile file or the metamodel.

## 9. Step 3: Identify

**What you can show:** ask a running component what it is, and get the model, the model revision and the build.

A digest is a fingerprint of a document or a file: a short text that changes whenever the content changes.

### Rules

| # | Rule |
|---|---|
| 3.1 | The manifest gets a second part, the binding. It names the twin, the metamodel and its version, the model revision, and the model element the component is the deployed form of. The model revision is one text, issued by the twin host. The binding does not repeat what the model says: which controllers and entity types the component has, and what it is meant to satisfy, the twin calculates from the model (section 6). |
| 3.2 | The generator writes the binding (rule G6), and the build adds the digest of the built component to it. Nothing about one deployment is in the manifest. |
| 3.3 | A component whose binding is missing or invalid still runs. It is "unbound": it says so where an operator can see it, reports nothing to the twin, and never guesses a binding. This is a warning, not a refusal. |
| 3.4 | A running instance can state its component identifier and version, the digest of its build, the digest of its manifest, its deployment and its instance. |
| 3.5 | An identifier is an opaque text. The framework does not shorten, build or interpret it, and holding one grants no right. |
| 3.6 | A measure gets a binding key in the manifest. So does a rule the twin may change (step 6). A setting is known by its own name. |

The exact fields are in `Aphrodites_3_Schemas/manifest.schema.json`, with examples beside it. The example manifest is the full one, for a framework at level T3. For this step, state level C and keep the binding: a framework that has reached step 3 is still at level C. For the next step, state level T1. Leave out the `control` part in both.

### How a reviewer checks

1. Start a component with a manifest and ask what it is. It gives the identities of rule 3.4, and the manifest it names gives the model and the model revision.
2. Start two instances of one build. Component, build and manifest are the same; the instance differs.
3. Remove the model revision from the binding. The component runs, shows itself as unbound and reports nothing.

### Settled and assumption

- **Settled:** the idea, which is the owner's Digital Thread draft: three identities (the model element, the build, the running instance) and a manifest that ties them together. That the component is the unit connected to the model, that an unbound component keeps running, and that the generator and the build each fill their own part are confirmed decisions. The owner's decisions of 24 November 2026: the binding refers to the model and does not copy it, and the model revision is one text.
- **Assumption:** the exact fields. The schema is a first proposal. That a twin host can calculate what a component has: the existing twin host cannot follow such a path by name today.

## 10. Step 4: Report

**What you can show:** the customer-inquiry application runs its four cases, and the twin holds a count for each (`Aphrodites_3_Reference_Customer_Inquiry.md`, section 4).

### Rules

| # | Rule |
|---|---|
| 4.1 | A report is an event from a component to the twin host, so rules 2.9 and 2.10 apply to it. At this step there are two kinds of report; step 5 adds the report on a change. A measure is a number for a measure the model declares. A lifecycle report gives the state of an instance: running, degraded or stopped. A business outcome of an operation, such as "found" or "not found", is counted, and the count is reported as a measure. No report is sent for a single execution. |
| 4.2 | A report names the manifest by its digest, and the instance. A measure also names what it is about by its binding key. A report carries no model identifiers: the twin host finds the model element through the manifest. So the twin host must hold the manifest before it can read a report. How the manifest reaches it is left open: with the deployment, or sent by the component. |
| 4.3 | A report carries no value of a business object, other than the number of a declared measure. Of the settings, it carries only the source it reports under, the origin of the data and the deployment. |
| 4.4 | A business operation is answered without waiting for the twin host. Reports that cannot be delivered are kept and sent when the twin host can be reached again. This is a warning. |
| 4.5 | The twin host's answer that it has taken a report in does not mean the report was recorded. To know, the framework reads the receipt back, as step 5 of the customer-inquiry scenario does. |
| 4.6 | A report says what held when it was made, and it is never changed afterwards. A correction is a new report, made later, that names the report it corrects by what the twin host's receipt gave for it. This holds for every kind of report. |
| 4.7 | A technical figure such as response time or processor load is not a measure, unless the model declares it. Traces go to a collector the deployer chooses, not to the twin. |

An operation that has outcomes counts each execution under exactly one of them. Which outcome a measure counts is the application's business: the manifest lists the measures, not the outcomes.

Over HTTP a report is a CloudEvents JSON event, which is what the existing twin host accepts today. Its exact fields are in `Aphrodites_3_Schemas/evidence.schema.json`.

### What the existing twin host does today

| Topic | Fact |
|---|---|
| Sending | One event per request, as structured CloudEvents JSON |
| Who may send | Each source has its own credential, and may send only what its connector is authorized for |
| Taken in | The host answers that the event is admitted and gives an admission identifier |
| Recorded | The admission is read back: `processed` means recorded. `rejected` and `failed` mean it was not. `uncertain` means the host cannot yet say |
| Corrected | A correction is a new measure that names the earlier one. The earlier one stays in the history and is no longer used as the current value |
| What it accepts | One kind: a decimal measure. It refuses any field it does not know |
| What it cannot do yet | Take the manifest digest or the instance in a measure; take a lifecycle report; take in a manifest; send a change to an application |

So the first proof against the existing twin host shows binding keys, units and recording. It does not show which build produced a report.

### How a reviewer checks

1. Run the level T1 scenario of the customer-inquiry reference. The twin holds a count of 1 for each of the four outcomes.
2. Read any report. It contains no customer data and no model identifier.
3. Make the twin unreachable and run an inquiry. The answer comes at once. After the twin returns and the period has ended, it holds one count for that period.
4. Report a measure whose binding key is not in the manifest. Nothing is sent.

### Settled and assumption

- **Settled:** the event envelope, the decimal measure, the origin of data, reading a receipt back and correcting a measure are the existing twin host's contract as it works today. Binding keys in place of model identifiers, and no telemetry in the twin, are confirmed decisions. The owner's decisions of 24 November 2026: outcomes are reported as counts only, and a report is an event between machines. The owner's decision of 26 November 2026: a report is never changed, and a correction is a new report that is linked to the original.
- **Assumption:** the lifecycle report, which the existing twin host cannot take yet, and with it the correction of any report other than a measure.

## 11. Step 5: Change a setting

**What you can show:** the twin changes how long the customer-inquiry application tells a caller to wait, and the next answer shows it (reference, section 5).

### Rules

| # | Rule |
|---|---|
| 5.1 | A change is approved in the twin before it is sent. Whoever proposes a change does not approve it; that holds for a person and for an AI alike. |
| 5.2 | A change arrives as one package. It says which component and which manifest it is for, the revision it expects to find, the revision it brings, the setting names with their new values, and until when it is valid. It carries the approval: who approved, when, and the digest of the package. It carries the twin host's proof for that approval: its signature on the content, which holds however the package travelled and whoever passed it on. |
| 5.3 | Before applying a change the component checks five things: the proof shows that the content is the twin host's; the package is the one that was approved; it is meant for this component in its present state; it is still valid; and the manifest allows that setting to be changed. If any check fails, or cannot be made, the change is refused and nothing changes. |
| 5.4 | A change takes effect whole or not at all, and at most once. A setting that needs a restart takes effect at the next start, and is reported as pending until then. |
| 5.5 | The component reports what happened to a change: applied, pending, refused or failed. A refusal or a failure gives the reason. Its lifecycle report names the revision in effect. A component has one revision for everything the twin changes while it runs, settings and rules alike. Delivery of a package is not proof that it took effect. |
| 5.6 | A component that cannot reach the twin keeps working on its last approved state. |
| 5.7 | Nothing a component does or observes changes the approved model. A difference is reported, never written back. |

To return to earlier values, the twin sends a new change. There is no separate "undo".

A package states its class: L1 for a setting, L2 for a rule (step 6), L3 for replacing the component (step 7).

The digest is SHA-256 over the document written in the fixed form of RFC 8785. The exact fields, examples and known answers are in `Aphrodites_3_Schemas/`.

### How a reviewer checks

1. Run the level T2 scenario of the customer-inquiry reference.
2. Alter one field of an approved package. It is refused.
3. Alter the approver's name. It is refused.
4. Send a package for a setting the manifest does not list. It is refused.
5. Send the same package twice. It is applied once.

### Settled and assumption

- **Settled:** the principles. A change is approved in the twin first; the approval covers the whole package through one digest; the proof also covers the approval, and is the twin host's signature on the content (the owner's decision of 24 November 2026); RFC 8785; the application keeps running without the twin. These are confirmed decisions and the owner's Digital Thread draft.
- **Assumption:** everything else. No twin host can send a change to an application today, so the package has never been used. Which kind of signature is not decided, nor how a component comes to trust the twin host's key.

## 12. Step 6: Change a rule

**What you can show:** a discount rule is switched on for Black Friday and changed back afterwards, with no restart and no new build.

### Rules

| # | Rule |
|---|---|
| 6.1 | The content of a rule can be changed from the twin at any time, one rule at a time, without a restart and without a new build. |
| 6.2 | A rule change travels and is checked like a setting change (step 5), and moves the same revision on. It names the rule by its binding key and carries no model identifiers. The manifest lists the rules that can be changed, each once, with its binding key and its model element. |
| 6.3 | New content stays within what the rule may read and change (1.16), or the change is refused. A change that needs a new entity type, value or relationship is a change of the model (1.17) and arrives as a new build (step 7). |

To end the discount, the twin sends the earlier content again.

The aim is that every business rule can be changed this way. A rule built into the component as code is the exception: it changes only with a new build.

### How a reviewer checks

1. In Filmology, change the content of the rule `silent_era_color` so that it applies before 1935 and not before 1930. A movie created afterwards with a release year of 1932 gets the color.
2. Send content that changes an entity the rule may not change. It is refused and the old content stays.
3. Send the earlier content again. The rule behaves as before.
4. Read the lifecycle report. It names the revision the change brought.

### Settled and assumption

- **Settled:** the owner's decisions of 24 November 2026. Rules are changed dynamically and at any time, they are defined less formally, and they never change data structures. Settings and rules share one revision.
- **Assumption:** everything about how. Because each framework chooses how rule content is written, a rule change written for one framework cannot be sent to another. Whether that is acceptable has to be learned.

## 13. Step 7: Replace a component

**What you can show:** version 1.0.0 of the customer-inquiry application is replaced by 1.0.1 on the twin's order, and its data is still there (reference, section 6).

### Rules

| # | Rule |
|---|---|
| 7.1 | A component can be replaced by another version while the other components keep serving requests. An operator can do it at the framework, and the twin can order it. |
| 7.2 | A replacement keeps the component's stored data. It also keeps what the twin changed: the settings and the rule contents, with their revision. If it fails at any point, the previous version is active again with all of these as they were. A replacement that offers no way back is refused before anything changes. |
| 7.3 | The twin's order is a change package (step 5). It names the new component by a reference and a digest. It names two manifests: the one in effect and the one the new version brings. It expects the version in effect and brings the new version. It leaves the revision of settings and rules as it is (7.2). |
| 7.4 | Before activating it, the framework checks that the new component is the one named, has the same component identifier and the version the package says, and has a valid binding. If not, the change is refused. |
| 7.5 | Code in a running component is changed in no other way. |

### How a reviewer checks

1. Replace a component by a version that fails to start. The previous version is active and its data is unchanged.
2. Run the level T3 scenario of the customer-inquiry reference.
3. Send a package whose new component does not match its digest. It is refused.
4. Replace one of two instances. Each reports its own build.
5. Change a setting, then replace the component. The setting keeps its changed value, and the revision is the same as before.

### Settled and assumption

- **Settled:** no replacement without a way back, and the two manifests in one package, are confirmed decisions. That a replacement keeps what the twin changed is the owner's decision of 24 November 2026.
- **Assumption:** everything else. How a component is packed, how its stored data is brought to a new shape and back, and what happens to a changed setting or rule that the new version no longer has, are left open on purpose.

## 14. Left out on purpose

The long drafts specified the following. None of it is needed to build the seven steps, and none of it has been tried. Each can come back when an implementation shows the need.

- How deep related entities are loaded, results page by page, and what happens when two requests change the same entity.
- One fixed set of ways in which every storage operation ends.
- What a rule can count or calculate, and what happens to a request in progress while a rule changes.
- A fixed list of the places where hand-written code may be called.
- Versions of event types, and a promised order of events.
- Starting and stopping a service, and its health.
- Several sources for one setting, and a filter on who may receive a result.
- One component requiring another.
- A record, per generated file, of the model elements it came from.
- How many reports may wait, which are dropped first, and a count of the dropped ones.
- A trace span around every operation.
- A report for every single execution of an operation. Outcomes are counted, and the counts are measures.
- A separate "undo" of a change, and names for how far a component is behind the twin.
- Applications other than servers, and with them views and the attaching of a view to a controller by an action key.

## 15. Open decisions

None of these has to be decided before testing starts. Each is decided when a test reaches it.

1. Partly settled by the owner on 24 November 2026: the proof on a change package is the twin host's signature on the content (rule 5.2). A proof of who sent a message is not enough, because on a mesh network a message passes through others. An RDO revision, signed by its owner, is the model. Still open: which kind of signature, and how a component comes to trust the twin host's key.
2. Whether every rule must be changeable at run time, or only those the manifest lists.
3. Whether one way of writing rule content should be shared between frameworks.
4. Settled by the owner on 26 November 2026: a report is never changed after it is made. A correction is a new report that is linked to the original, for every kind of report (rule 4.6). The existing twin host does this for a measure today.
5. How the manifest reaches the twin host. On Reticulum, RDO's package and file layer (RPP) is a candidate. It was not examined for this.
6. Settled by the owner on 24 November 2026: the model revision is one text (rule 3.1). An overlay is like a branch. It is never a permanent part of a twin.
7. Settled by the owner on 26 November 2026: this specification lives in the repository of the Digital Architecture Framework.
8. The `config` property of an action key, which says where the key is defined. This text does not use it.
9. Settled by the owner on 24 November 2026: rules 2.9 and 2.10 stand, and a report to the twin host is such an event (rule 4.1).
10. Reports over a mesh network. The existing twin host takes reports over HTTP only, and a report as CloudEvents JSON does not fit one LXMF packet. RDO's replication over LXMF is a candidate: it sends an owner's records to chosen receivers and confirms each one only when it is safely stored. Its form on the wire is not specified yet.
11. Information across components (section 2). Written on 26 November 2026 at the owner's word: rule 2.1 is reworded, and rule 2.14 is new. DAF 7 needs no new statement for them. It already says which component holds which entity type and how model classes are related, and who owns an entity type is calculated, as the owner of this text decided: it is the component that works on the type and also offers it through a service (section 6). Not settled:
    - Three cases of ownership: a type that two components both work on and offer, a type that several work on and none offers, and how a copy is told from a reference.
    - What a composition or an aggregation means across components, and what the default of rule 1.7 is when the needed entity belongs to another component.
    - What happens to a relationship when the owner deletes the entity it leads to.
    - Finding entities by a value of a related entity (1.8) when another component owns that entity.

    The policy-inquiry reference (`Aphrodites_3_Reference_Policy_Inquiry.md`) shows the two rules and none of the points above. The owner approved it on 26 November 2026. It is not built.

    Not proposed: RDO's own grain, where every value and every relationship has its own address on the network. That stays a candidate where Reticulum is used.
