# Aphrodites 3.0: certification sheet for step 1, "Run"

**Status:** second version, 26 November 2026, for Filmology revision 2. Every rule of step 1 now has a case. Not used on any framework yet.

One sheet is filled in for each framework of version 3. The same rows also record what the frameworks of versions 1 and 2 do, so that the change between the versions can be read rule by rule. Those two columns carry no verdict: wCMF and DigitalPy were built for their own versions and are not expected to comply with this one.

## The verdict

For a framework of version 3:

| Verdict | When |
|---|---|
| Compliant with step 1 | Every row of the table is shown |
| Not compliant | At least one row fails. The verdict names the rules |
| Not certified | No row fails, and at least one row was not checked |

## What is run

- **Scenario:** the 20 steps of `Aphrodites_3_Reference_Filmology.md`, revision 2, called through the service.
- **Checks 2 to 5** of step 1 in `Aphrodites_3_Specification.md`.
- **Also:** five short runs that the table names. They use the entities the scenario has left behind.
- **Look:** a reviewer reads the framework or the application. Nothing is run.

## Rule by rule

Write "shown", "fails" or "not checked" in the column of a version 3 framework. In the columns of versions 1 and 2, "differs" means that the framework does not do what the rule says, in at least one part.

| Rule | Shown by | Version 3, DigitalRust | Version 2, DigitalPy | Version 1, wCMF |
|---|---|---|---|---|
| 1.1 Identifier | Scenario 3 to 14: an entity keeps its identifier. Also: an entity that is constructed and not yet stored already has it | | differs | differs |
| 1.2 Values | Scenario 1 and 2. Check 2 for a read-only value. Scenario 15 and 16 for a value reference | | differs | differs |
| 1.3 Checks in memory | Scenario 2. Look: the refusal comes when the entity is constructed, before anything is saved, and names the restriction | | differs | differs |
| 1.4 Relationships keep the model | Scenario 9, 10 and 12. Also: create a second primary poster for movie M2. Refused | | differs | differs |
| 1.5 Three kinds of relationship | Scenario 4, 5, 6, 9, 12 and 13 | | differs | differs |
| 1.6 Inheritance, abstract types | Scenario 3 and 6. Check 2 | | differs | not checked |
| 1.7 Created with defaults | Scenario 4 and 5 | | differs | differs |
| 1.8 Storage operations | Scenario 1, 3, 4, 6, 8, 10, 11, 13 and 14. Look: none of them is hand-written | | differs | not checked |
| 1.9 Stored together or not at all | Also: create a movie with a poster and a director that does not exist. Refused, and neither the movie nor the poster is stored | | differs | not checked |
| 1.10 A failing store is not "not found" | Check 3 | | not checked | not checked |
| 1.11 The store only through the operations | Look: the application reaches the store in no other way | | differs | not checked |
| 1.12 Operations | Look: each operation has a unique name, typed input and output, and one method | | differs | differs |
| 1.13 Input checked first | Check 4 | | differs | differs |
| 1.14 How a request ends | Scenario 2 and 14. Checks 3 and 4. Also: an operation that does not exist is refused as unknown. Also: the failure answer of check 3 holds no stored data and no technical detail | | differs | differs |
| 1.15 Actions and action keys | Scenario 17. Look: MovieController does not read the director itself; the action key leads to `read_director` of CatalogueController | | not checked | differs |
| 1.16 A rule is a named unit | Scenario 4, 7, 11 and 18. Look: each rule says what it reads and what it may change | | differs | differs |
| 1.17 A rule never changes structure | Look: the rule cannot add or change a value, a type or a relationship | | differs | differs |
| 1.18 Production rules | Scenario 4, 7, 11 and 18 | | differs | differs |
| 1.19 A rule's changes, all or none | Scenario 18, 19 and 20. Write down whether the runtime change of step 20 is itself stored | | differs | differs |
| 1.20 The service is a channel | Check 5. Look: the service holds no logic, no rules and no data | | not checked | not checked |
| 1.21 Networks and descriptions | Look: the framework states its networks, and the service description lists the Filmology operations with their types | | differs | differs |
| 1.22 Endings told apart on the network | Scenario 2 and 14, and checks 3 and 4, read from the answers on the network | | not checked | differs |

## The columns of versions 1 and 2

The DigitalPy column is the first look of 26 November 2026: DigitalPy as published, with its own Filmology example, which was not brought to revision 2. What was seen for each rule is in `Aphrodites_3_Step1_Result_DigitalPy.md`.

The wCMF column is from the same day, from reading only: wCMF as published, with nothing run. What the code does for each rule is in `Aphrodites_3_Step1_Result_wCMF.md`. wCMF has no Filmology example.

DigitalPy's Filmology example is where the reference comes from, but the reference changed its model in five places and added three things (reference, section 2). The full scenario can be run on DigitalPy only after the example is brought to revision 2.
