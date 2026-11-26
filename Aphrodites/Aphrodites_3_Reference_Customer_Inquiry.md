# Aphrodites 3.0: reference application "Customer inquiry", revision 1

**Status:** revision 1, approved by the owner on 24 November 2026 as the reference for the digital thread. Changed since then, to follow the specification: in section 5 an undo is a second change; in section 6 a failed replacement is reported as `failed`, the setting is changed first, and the revision survives a replacement; the binding in section 3 lists no elements, operation or outcomes; section 4 expects counts in place of one report per inquiry.

**Source:** the customer inquiry of GenApp, IBM's sample insurance application, as a modernization demonstration rebuilt it as a generated service. It was read from the generation model of that demonstration, which is not public.

## 1. What it is for

Customer inquiry is the reference for the digital thread, levels T1 to T3. It is small on purpose: one operation with four outcomes.

## 2. The application

| Item | Value |
|---|---|
| Service | EuroCom Customer Inquiry, version 1.0.0 |
| Operation | `inquire_customer`: read one customer by customer number |
| Stored type | Customer, in one table keyed by customer number |
| Seed data | Three customers: `0000000042`, `0000000107` and `0000000203` |

The four outcomes, with the answers the demonstration gives on the network:

| Outcome | When | Answer |
|---|---|---|
| `found` | The customer exists | 200, code 00 |
| `not_found` | No customer has that number | 404, code 01 |
| `contention` | The customer records are busy | 503, code 01 |
| `storage_error` | The customer records cannot be read | 500, code 90 |

## 3. Binding

| Manifest entry | Value |
|---|---|
| Measures | One per outcome: its count in a period, bound to its own measurement indicator, in the unit "inquiry" |
| Changeable setting, for level T2 | `retry_after_seconds`, a whole number, default 5: what the `contention` answer tells the caller to wait, in its HTTP `Retry-After` header |
| Rules | None |

The setting is proposed here. The demonstration does not have it yet.

The worked manifest in `Aphrodites_3_Schemas/` declares one count measure for each of the four outcomes. Its binding does not list the operation or the outcomes themselves. Outcomes are reported as counts only: no report is sent for a single inquiry. The existing twin host accepts measures today. To run the exercise against it, the twin needs the four indicators and a connector that is bound to them, and the reports must leave out `binding` and `instance`, which it refuses.

## 4. Scenario for level T1

Run in order. Each run is one request. Steps 1 to 4 fall in one reporting period, and step 7 in a later one.

| Step | Request and condition | Expected answer | Expected evidence |
|---|---|---|---|
| 1 | Inquire `0000000042` | `found` | The count of `found` is 1 |
| 2 | Inquire `0000000999`, which does not exist | `not_found` | The count of `not_found` is 1 |
| 3 | Inquire `0000000042` while another writer holds a lock that prevents the read | `contention` | The count of `contention` is 1 |
| 4 | Inquire `0000000042` while the store cannot be opened | `storage_error` | The count of `storage_error` is 1 |
| 5 | End the period, and read each report's receipt from the twin host | | Four measures are recorded, each once, each with the value 1 |
| 6 | Inspect every report | | None contains a customer's name, number or any other stored value |
| 7 | Make the twin host unreachable; inquire `0000000042`; make it reachable again and end the period | `found`, without delay | The count of `found` for the later period is recorded once after the host returns |

## 5. Scenario for level T2

| Step | Change and condition | Expected |
|---|---|---|
| 1 | Report state | Revision 1 |
| 2 | A valid class L1 package sets `retry_after_seconds` to 30, from revision 1 to revision 2 | Evidence reports `applied`, from 1 to 2 |
| 3 | Repeat step 3 of section 4 | `contention`; the answer's `Retry-After` header says 30 |
| 4 | The same package arrives again | Answered with the first outcome; revision 2 stays |
| 5 | A package that expects revision 1 arrives | Refused; revision 2 stays |
| 6 | A second valid package sets `retry_after_seconds` back to 5, from revision 2 to revision 3 | Evidence reports `applied`; revision 3 is in effect |
| 7 | Repeat step 3 of section 4 | `contention`; the `Retry-After` header says 5 again |

There is no class L2 step, because this application has no rule.

## 6. Scenario for level T3

| Step | Change and condition | Expected |
|---|---|---|
| 1 | A valid class L1 package sets `retry_after_seconds` to 30, from revision 3 to revision 4 | Evidence reports `applied`; revision 4 is in effect |
| 2 | A valid class L3 package replaces version 1.0.0 by version 1.0.1, with no change to stored data | The new build is active; lifecycle evidence carries the new artifact digest in `build` and the new manifest digest in `binding`, and the revision is still 4 |
| 3 | Inquire `0000000042` | `found`: the stored customer is still there |
| 4 | Repeat step 3 of section 4 | `contention`; the `Retry-After` header still says 30 |
| 5 | A class L3 package whose new version fails to start | The old build is active; the change is reported as `failed` |

## 7. What is assumed

- The demonstration's records say its tests cover the four outcomes on the generated FastAPI service, with real contention on the store. They were not run for this text.
- Reporting outcomes as counts needs four measurement indicators in the twin and a connector authorized for them. Whether they exist was not checked.
- The existing twin host cannot record the revision of a component. Sections 5 and 6 cannot be shown against it today.
- How long a reporting period is. The scenario only needs steps 1 to 4 in one period and step 7 in a later one.
