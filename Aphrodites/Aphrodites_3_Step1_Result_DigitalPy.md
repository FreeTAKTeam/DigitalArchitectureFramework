# Aphrodites 3.0, step 1: what DigitalPy does (version 2)

**Status:** first baseline, 26 November 2026. DigitalPy as it is published, commit `910745e` of 12 June 2026, with its own Filmology example. The example was not brought to revision 2 of the reference.

## What this is

DigitalPy is the framework of version 2: it implements Aphrodites 2.0. It was built for that version and is not expected to comply with version 3. This file documents the change between the two versions: for each rule of step 1 of version 3, what DigitalPy does today. It is not a test of DigitalPy, and a difference is not a fault.

**In short:** of the 22 rules, 18 differ, 4 were not checked, and none is shown in full. What version 2 added to version 1 lies mostly in step 2, which was not looked at.

## How it was checked

- **Run:** the example was driven in the process, the way DigitalPy's own test does, on Python 3.13 with a SQLite store in a scratch folder. It was not called through a network service. The script and its two outputs are in `Aphrodites_3_Step1_Evidence_DigitalPy/`.
- **Read:** the framework and the example were read against each rule. For the rows marked "read", nothing was run.
- Only the scenario steps that the published example can do were run: creating a date, a director, a poster and a movie, reading, and deleting. Steps 6 to 20 were not run.

Three things to know before reading the table:

- **On Linux the example cannot create anything as published.** The framework looks for `date.json` and the example ships `Date.json` (`digitalpy/core/parsing/load_configuration.py`, line 31). Every create ends without an answer. The run below uses a work-around in the test script; DigitalPy itself was not changed.
- **DigitalPy's own Filmology tests are switched off.** The test file skips itself.
- **"Differs" means the published framework with its published example.** Where the framework has a part that the example does not use, the note says so.

## Rule by rule

| Rule | Result | How | What was seen |
|---|---|---|---|
| 1.1 Identifier | Differs | Run, read | An entity has its identifier when it is constructed. But a caller can choose the identifier in the request, and it can be set again later |
| 1.2 Values | Differs | Run | A date with the year "927" is stored. A list given as the year is stored as the text "[1, 2]". There is no read-only value and no value reference |
| 1.3 Checks in memory | Differs | Run | Nothing is checked when an entity is constructed. The only refusal comes from the store when it saves, and the caller gets no answer that names it |
| 1.4 Relationships keep the model | Differs | Run, read | A date that a movie is released on can be deleted. In the example a relationship is a plain identifier. The framework has a relationship class with kind, multiplicity and direction; the example does not use it |
| 1.5 Three kinds of relationship | Differs | Run | A poster is created on its own and then attached. Deleting the movie leaves its poster |
| 1.6 Inheritance, abstract types | Differs | Read | Every entity type extends the base class directly, with the values copied into each. The types meant to be abstract can be constructed |
| 1.7 Created with defaults | Differs | Run | A movie with nothing but its name is rejected by the store. Nothing is created by default. The framework can create required children at construction; the example never triggers it |
| 1.8 Storage operations | Differs | Run, read | Reading a movie by an identifier that does not exist returns another movie. Deleting one date deleted all three. The storage operations are about 950 lines in the application; the framework's own storage layer is unfinished |
| 1.9 Stored together or not at all | Differs | Read | A request has no transaction. The call that should end one is defined nowhere, and each storage call commits by itself |
| 1.10 A failing store is not "not found" | Not checked | Run in part | In the process, a store that cannot be opened raises an error. Not run through a service |
| 1.11 The store only through the operations | Differs | Read | The application uses the database library directly and has the path of the SQLite file in its code |
| 1.12 Operations | Differs | Read | An operation has a name and one method, but no typed input or output. Names are shared by all components |
| 1.13 Input checked first | Differs | Run | Input of the wrong type is accepted and the method runs |
| 1.14 How a request ends | Differs | Run | An unknown operation, a create the store rejects and a failure all end the same way: no answer, only a line in the log. A missing movie is not reported as "not found" |
| 1.15 Actions and action keys | Not checked | Read | The example has no action from one controller to another. The framework does resolve action keys, and an empty action or context fits any. By reading, an empty method runs nothing, which the rule does not allow |
| 1.16 A rule is a named unit | Differs | Read | The framework's rule code has no named rule with a statement and with what it reads and may change. Nothing uses it, and the example has no rule |
| 1.17 A rule never changes structure | Differs | Read | A rule's consequence is to run operations. Nothing limits what they change |
| 1.18 Production rules | Differs | Run, read | A movie released in 1927 with an empty color keeps it empty: no rule runs anywhere. A rule's condition can be an expression; its consequence cannot set a value |
| 1.19 A rule's changes, all or none | Differs | Read | What a rule changes is not checked, and nothing keeps its changes together |
| 1.20 The service is a channel | Not checked | Read | By reading, the networks sit behind one interface and the service only passes requests on. The example offers HTTP only, so one operation through two interfaces was not run |
| 1.21 Networks and descriptions | Differs | Read | The networks are stated. An OpenAPI file exists, but nothing serves or produces it, and it disagrees with the application: its movie has three relationships that the application's movie does not have |
| 1.22 Endings told apart on the network | Not checked | Read | Not run through a service. By reading, HTTP answers with 200 or 500 only |

## What this baseline can and cannot say

- It says where DigitalPy stands today against step 1, as published.
- Ten of the 18 differences were seen in a run. The other eight rest on reading the code, and the decisive lines were checked a second time.
- It does not say how far DigitalPy would get with a Filmology example brought to revision 2. For most of the 18 rules the part is not in the framework itself, so the picture would not change.
- The four rows that were not checked need the example to run behind a service.
