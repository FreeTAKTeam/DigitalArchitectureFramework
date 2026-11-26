# Aphrodites 3.0: schemas and examples

**Status:** sixth version, 26 November 2026. Cut down to what the short specification needs, and cut again after the review for over-engineering. The binding does not list the model elements a component implements or satisfies: the twin calculates them from the model. There is no report for a single execution: an outcome is counted, and the count is a measure. New in this version: the manifest lists a changeable rule once, under `control`, and every kind of report can name the report it corrects. A first proposal: expect the fields to change with the first implementation.

## What is here

| File | Shows | Specification |
|---|---|---|
| `manifest.schema.json` | The one document that describes a component | Steps 2 and 3 |
| `evidence.schema.json` | The three kinds of report a component sends | Step 4, and step 5 for the change report |
| `change-package.schema.json` | A change the twin sends to a component | Steps 5 to 7 |
| `examples/valid/` | 9 documents that fit | |
| `examples/invalid/` | 4 documents that do not, each for one reason | |
| `check_examples.py` | Checks all of them | |

Start with the examples. They are easier to read than the schemas.

## How to run the check

```bash
python3 check_examples.py
```

It needs the Python package `jsonschema`. It prints one line per check and ends with exit code 0 when everything is as expected.

It checks three things: every example against its schema; on a change package, the digest named in the approval and the proof; and that a package or a report names a manifest that is among the valid examples.

## The examples

| File | What it is |
|---|---|
| `manifest-customer-inquiry.json` | The customer-inquiry component in full, for a framework at level T3: its binding and what the twin may change. For level T1 alone, state level T1 and leave out `control` |
| `manifest-filmology.json` | A cut-down Filmology manifest that shows one changeable rule, listed once under `control`. The real application has two controllers and nine entity types |
| `manifest-component-only.json` | A component at level C, with no binding. It runs unbound |
| `evidence-measure.json`, `evidence-lifecycle.json`, `evidence-change.json` | One report of each kind, about the customer-inquiry manifest. The measure is the count of the outcome `found` in one hour |
| `package-l1-setting.json` | The twin sets `retry_after_seconds` to 30 |
| `package-l2-rule.json` | The twin changes the content of the rule `silent_era_color`. The content is plain text here; how a framework writes rule content is its own choice |
| `package-l3-replacement.json` | The twin replaces version 1.0.0 by 1.0.1 |

| Invalid file | What is wrong | What happens |
|---|---|---|
| `package-missing-approval.json` | No approval | Refused |
| `package-altered-after-approval.json` | The value was changed after approval | Refused: the digest no longer fits |
| `package-altered-approver.json` | The approver's name was changed | Refused: the proof no longer fits |
| `evidence-with-model-identifier.json` | The report carries a model identifier | Refused by the twin host |

There are no invalid manifests here. To see the two cases, edit `manifest-customer-inquiry.json`: remove its version and the component is refused; remove the model revision from its binding and the component runs unbound.

## Digests

A digest is SHA-256, written as `sha256:` and 64 lower-case hexadecimal digits. The document is first written in one fixed form: RFC 8785, in short UTF-8, members sorted by name, no white space.

| Digest | Taken over |
|---|---|
| Manifest digest | The whole manifest |
| Package digest | The change package without `approval` and `proof` |
| Approval digest | The `approval` member, which holds the package digest |

The proof on a package is for the approval digest. So altering the package breaks the digest, and altering the approver or the time breaks the proof.

The examples use a made-up kind of proof, `example-hmac-sha256`: HMAC-SHA256 with the public test key `aphrodites-example-key`, over the approval digest as text (`sha256:` and its 64 digits, no line end). It only shows that a proof can be checked. It is not the real proof: that is the twin host's signature on the content, decided on 24 November 2026. Which kind of signature, and how a component gets the twin host's key, are not decided.

### Known answers

Another implementation should get the same values. The check fails if they change.

| Value | From | Result |
|---|---|---|
| Manifest digest | `manifest-customer-inquiry.json` | `sha256:5ce2d8d72ce65c20ab735805c80047f2fc566171790149ff06c75ae31e78d979` |
| Package digest | `package-l1-setting.json` | `sha256:9679ccf7db35d35b4a4dd47351731d203da8d6e495cf7b9e2aac9310dcdcc884` |
| Approval digest | The same file | `sha256:08c7460e53f5f5918d2ba188b78917260cfc4a94418c0a50784ebb84f61132ca` |
| Proof | The same file | `dc46dcd2d079ec88b0a83e5797b7621cc8a758e40c803566d652852e33579f09` |

## What is made up

- Every other digest in the examples: the build, the generator's input, the new component and its manifest in the replacement package.
- The model identifiers, which start with `urn:example:`.
- The event type names (`org.freetakteam.aphrodites.…`), which are proposed.

## Limits

- Nothing here has been run against a framework or against a twin host.
- The existing twin host accepts only the measure today, and without the fields `binding` and `instance`.
- No example shows a correction. A correction is a new report with `supersedes_digest`, which holds what the twin host's receipt gave for the report it corrects (rule 4.6).
- The check does not compare a package with what the manifest allows. A framework does that (specification, rule 5.3).
- The check does not require the revision in the state report of a component at level T2 or T3, although rule 5.5 asks for it. The schema cannot know the level.
- After editing an example, the digests that depend on it must be corrected by hand. The check prints the values it computes.
