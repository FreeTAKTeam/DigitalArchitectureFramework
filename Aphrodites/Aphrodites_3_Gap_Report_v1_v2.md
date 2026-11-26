# Aphrodites: what changed from versions 1 and 2 to version 3

**Status:** first report, 26 November 2026. It covers step 1 of version 3 only ("Run": data, storage, operations, rules and the service).

## What this report is

Aphrodites had two versions before this one, and each has its framework.

| Version | Its framework | How it was looked at |
|---|---|---|
| 1 | wCMF, in PHP. The first version of Aphrodites was written with it: the original specification describes the architecture of wCMF, and the author of wCMF is one of its two authors | By reading its published code |
| 2 | DigitalPy, in Python. It implements Aphrodites 2.0, which added components, services and access control | By a run, and by reading its published code |
| 3 | DigitalRust, in Rust. It will be the only framework of version 3 | Not started |

Version 3 is the text `Aphrodites_3_Specification.md`.

wCMF and DigitalPy were built for their own versions. Neither is expected to comply with version 3, and this report is not a test of them. It documents the change between the versions: for each rule of step 1 of version 3, how much of it the framework of an earlier version already does. What is not there is what version 3 changes or adds. It is not a fault of the earlier framework.

## The change in short

| Part of step 1 | Rules | Version 1 (wCMF) | Version 2 (DigitalPy) |
|---|---|---|---|
| Data | 1.1 to 1.7 | Partly there. Restrictions are checked when a value is set, and deleting a parent deletes what it owns. Not there: a fixed identifier from the start, a check at construction, minimum numbers, defaults by convention | Mostly not there. Values and relationships are not checked, and entity types do not inherit |
| Storage | 1.8 to 1.11 | Reads as there, with transactions. Not run | Not in the framework. The application carries its own storage code |
| Operations and actions | 1.12 to 1.15 | Action keys are there. Not there: typed input, and a check of the input before the method runs | Action keys are there. Not there: typed input, the input check, and endings a caller can tell apart |
| Rules | 1.16 to 1.19 | Not there. It has no business rules | Not in use. It has rule code, and nothing uses it |
| Service | 1.20 to 1.22 | Partly there, over HTTP only. A machine-readable description exists for SOAP, not for REST | Partly there. Several networks are offered, Reticulum among them. The description is not served and disagrees with the application |

| Count over the 22 rules | Version 1 (wCMF) | Version 2 (DigitalPy) |
|---|---|---|
| Not there | 5 | 13 |
| Partly there | 10 | 5 |
| Close | 1 | 0 |
| Not checked | 6 | 4 |

## Rule by rule

| Rule | Version 1 (wCMF) | Version 2 (DigitalPy) |
|---|---|---|
| 1.1 Identifier | Partly | Partly |
| 1.2 Values | Partly | Not there |
| 1.3 Checks in memory | Partly | Not there |
| 1.4 Relationships keep the model | Partly | Partly |
| 1.5 Three kinds of relationship | Partly | Not there |
| 1.6 Inheritance, abstract types | Not checked | Not there |
| 1.7 Created with defaults | Partly | Partly |
| 1.8 Storage operations | Not checked | Not there |
| 1.9 Stored together or not at all | Not checked | Not there |
| 1.10 A failing store is not "not found" | Not checked | Not checked |
| 1.11 The store only through the operations | Not checked | Not there |
| 1.12 Operations | Partly | Partly |
| 1.13 Input checked first | Not there | Not there |
| 1.14 How a request ends | Partly | Not there |
| 1.15 Actions and action keys | Close | Not checked |
| 1.16 A rule is a named unit | Not there | Not there |
| 1.17 A rule never changes structure | Not there | Not there |
| 1.18 Production rules | Not there | Not there |
| 1.19 A rule's changes, all or none | Not there | Not there |
| 1.20 The service is a channel | Not checked | Not checked |
| 1.21 Networks and descriptions | Partly | Partly |
| 1.22 Endings told apart on the network | Partly | Not checked |

What each framework does for each rule is in `Aphrodites_3_Step1_Result_wCMF.md` and `Aphrodites_3_Step1_Result_DigitalPy.md`.

## What is new in version 3

Neither earlier version has these:

- Business rules as named units, each saying what it reads and what it may change (rules 1.16 to 1.19).
- A check of the input before the method runs (rule 1.13).
- An identifier that is fixed from the moment an entity is constructed (rule 1.1).
- Everything an entity needs created with it by default (rule 1.7).
- The digital thread, steps 3 to 7. It is the main addition of version 3, and neither framework was looked at for it.

## How far this report can be trusted

- **Step 1 only.** What version 2 added to version 1 lies mostly in step 2: components installed while the framework runs, events, several networks, access. None of that was looked at, so this report shows less of version 2 than there is.
- **The two were not looked at alike.** DigitalPy was run, with its own Filmology example as published. wCMF was only read, and it has no Filmology example.
- **A difference is measured against version 3.** Some of these rules were decided only for version 3.
- **Nothing here says that either framework works, or that it does not.** No rule was shown in full for either.
