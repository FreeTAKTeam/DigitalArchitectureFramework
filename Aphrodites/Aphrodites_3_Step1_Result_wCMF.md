# Aphrodites 3.0, step 1: what wCMF does (version 1)

**Status:** first baseline, 26 November 2026, from reading only. wCMF as it is published, commit `1abe12a` of 10 February 2026. Nothing was run.

## What this is

wCMF is the framework that the first version of Aphrodites was written with: the original specification describes its architecture, and the author of wCMF is one of its two authors. wCMF was built for version 1 and is not expected to comply with version 3. This file documents the change between the two versions: for each rule of step 1 of version 3, what wCMF does. It is not a test of wCMF, and a difference is not a fault.

**In short:** of the 22 rules, 16 differ and 6 were not checked. No rule is "shown", because nothing was run. Of the 16, 5 are a part that version 1 does not have: the four rules on business rules, and the check of input before a method runs. The other 11 are partly there. Step 1 of version 3 is much closer to wCMF than to DigitalPy.

## How it was checked

- **Read:** the framework was read against each rule. The decisive lines were then checked a second time.
- **Not run.** This machine has no PHP. A run also needs wCMF's packages, Ant, and wCMF's test application, which has to be generated from its model first.
- **No Filmology.** wCMF has no Filmology example. Its test model has publishers, authors, books, chapters and images.
- **Generated code is not in the repository.** The entity classes, the mappers and the main configuration of the test application are produced by the generator. Where a rule depends on them, the row says "not checked".

What the words mean here:

| Word | Meaning |
|---|---|
| Differs | Reading shows that the published code does not do what the rule of version 3 says, in at least one part |
| Not checked | The code reads as doing it, or the deciding code is generated and not in the repository |

## Rule by rule

| Rule | Result | How close | What the code does |
|---|---|---|---|
| 1.1 Identifier | Differs | Partly | A new entity gets a temporary identifier. It is replaced by a number from the database when the entity is first saved |
| 1.2 Values | Differs | Partly | A restriction is checked when a value is set. The type is not checked on set. "Read-only" is recorded and never enforced. A value reference exists and is filled on read, but setting it is not refused |
| 1.3 Checks in memory | Differs | Partly | A refused set leaves the value as it was and names the field. But the values an entity is constructed with are not checked, and how many related entities it needs is never checked |
| 1.4 Relationships keep the model | Differs | Partly | A relationship carries kind, multiplicity, role names and direction. Only the maximum of a many-valued end is enforced. A minimum is never enforced, and a direction that is not allowed gives nothing back and is not refused |
| 1.5 Three kinds of relationship | Differs | Partly | Deleting a parent deletes its composition children and unlinks the others, as the rule says. But creating through the parent and attaching are allowed for every kind |
| 1.6 Inheritance, abstract types | Not checked | | The generator does this, and its output is not in the repository. The framework itself has no notion of an abstract type |
| 1.7 Created with defaults | Differs | Partly | Required children are created with default values only when the caller asks for it. A related entity that exists on its own, such as a director, is never created |
| 1.8 Storage operations | Not checked | | Reads as met: create, read by identifier, find by own values and by related entities, update, delete, attach, detach and list are in the framework, and the mappers are generated |
| 1.9 Stored together or not at all | Not checked | | Reads as met for a controller that asks for a transaction: the request's changes are committed at the end, and rolled back when it fails |
| 1.10 A failing store is not "not found" | Not checked | | Reads as met: a store failure ends as an error, a missing entity as "not found" |
| 1.11 The store only through the operations | Not checked | | Reads as partly met: the store is behind an interface, but only a relational store exists, a query can take SQL text, and the database connection is public |
| 1.12 Operations | Differs | Partly | An operation has a name and one method. Its input and output are untyped lists of names and values |
| 1.13 Input checked first | Differs | Not there | A request goes straight to the method. The checks are inside the methods |
| 1.14 How a request ends | Differs | Partly | Invalid input, not allowed and invalid action are separate errors, and "not found" is not an error. But an operation with no matching key ends silently, and a failure answers with the text of the internal error |
| 1.15 Actions and action keys | Differs | Close | Action keys work as the rule says: sender, context and action decide, and an empty one fits any. Only the empty method differs: it runs the controller's default method, not the method with the action's name |
| 1.16 A rule is a named unit | Differs | Not there | The framework has no business rules. It has checks of single values, callbacks on saving, and events |
| 1.17 A rule never changes structure | Differs | Not there | No business rules |
| 1.18 Production rules | Differs | Not there | No business rules |
| 1.19 A rule's changes, all or none | Differs | Not there | No business rules |
| 1.20 The service is a channel | Not checked | | Reads as mostly met: the formats are separate, and REST and SOAP lead to the same operations. The REST controller holds some logic of its own |
| 1.21 Networks and descriptions | Differs | Partly | HTTP only, which the rule allows. SOAP has a description a machine can read, built from generated code. REST has none |
| 1.22 Endings told apart on the network | Differs | Partly | Over REST each ending has its own error code. Over SOAP every error is the same fault with a message only |

## What this baseline can and cannot say

- It says what the published framework code does and does not do, rule by rule.
- It cannot say that anything works. No row was run, so no row is "shown".
- The six rows that were not checked need a run with the generated test application.
