# Aphrodites 3.0

Aphrodites says what a framework must provide so that an application generated from a DAF 7 model runs on it and stays connected to that model. The connection between the running application and the model is the digital thread, the main addition of version 3.0.

**Status:** version for testing, 26 November 2026. Many of its concepts are new and have not been tried. No decision in it is final: each one is confirmed or changed by what testing shows.

**Licence:** Creative Commons Attribution, crediting both authors of the original Aphrodite specification.

## The versions

| Version | Its framework |
|---|---|
| 1 | wCMF, in PHP. The first version of Aphrodites was written with it: the original specification describes the architecture of wCMF, and the author of wCMF is one of its two authors |
| 2 | DigitalPy, in Python. It implements Aphrodites 2.0, which added components, services and access control |
| 3 | DigitalRust, in Rust. It will be the only framework of this specification, and it is not started |

wCMF and DigitalPy were built for their own versions. They are not expected to comply with version 3, and nothing here is a test of them. The comparison documents the change between the versions: for each rule of step 1, what the framework of an earlier version does, and so what version 3 changes or adds.

## What is here

| File | What it is |
|---|---|
| `Aphrodites_3_Specification.md` | The specification: 70 rules in seven steps. Start here |
| `Aphrodites_3_Reference_Filmology.md` | Reference application for step 1 and for a generator |
| `Aphrodites_3_Reference_Customer_Inquiry.md` | Reference application for the digital thread |
| `Aphrodites_3_Reference_Policy_Inquiry.md` | Reference application for two components that share information |
| `Aphrodites_3_Schemas/` | The manifest, the report and the change package as JSON Schema, with examples and a script that checks them |
| `Aphrodites_3_Step1_Certification.md` | The sheet that decides whether a framework of version 3 is compliant with step 1 |
| `Aphrodites_3_Gap_Report_v1_v2.md` | What changed from versions 1 and 2 to version 3, for step 1 |
| `Aphrodites_3_Step1_Result_wCMF.md`, `Aphrodites_3_Step1_Result_DigitalPy.md` | What wCMF and DigitalPy do for each rule of step 1 |
| `Aphrodites_3_Step1_Evidence_DigitalPy/` | The script that was run on DigitalPy, and its output |

## How it is tested

One step at a time. Build the step on a framework, run its checks, correct the specification from what was learned, and only then start the next step.

To check the examples of the schemas, with the Python package `jsonschema` installed:

```bash
python3 Aphrodites_3_Schemas/check_examples.py
```
