# Aphrodites 3.0: reference application "Policy inquiry", revision 1

**Status:** revision 1, approved by the owner on 26 November 2026 as the reference for two components that share information. Written the same day. Nothing of it is built or generated.

**Source:** GenApp, IBM's sample insurance application, which the customer-inquiry reference also comes from. Its shared record layout (`lgcmarea.cpy`) describes a policy: a policy number, the customer number it belongs to, and common details. The modernization demonstration behind the customer-inquiry reference has no policy program and no generation model for one, so everything below the record layout is proposed here.

## 1. What it is for

Policy inquiry is the reference for two components that share information. It runs beside the customer-inquiry application (`Aphrodites_3_Reference_Customer_Inquiry.md`), which is not changed.

It shows four rules of step 2: a component's data has one owner (2.1), components are installed and removed while others keep answering (2.3), a flow leads from one component to a public operation of another (2.4), and a relationship leads to an entity that another component owns (2.14).

## 2. The application

| Item | Value |
|---|---|
| Service | EuroCom Policy Inquiry, version 1.0.0 |
| Component identifier | `policy-inquiry` |
| Operation | `inquire_policy`: read one policy by policy number. The answer gives the policy and its holder |
| Stored type | Policy, in one table keyed by policy number |
| Values of a policy | `policyNumber`, ten digits; `issueDate`; `expiryDate`. They are GenApp's policy number and the first two of its common policy details |
| Seed data | Three policies, see below |

| Policy | Holder |
|---|---|
| `0000000301` | Customer `0000000042` |
| `0000000302` | Customer `0000000042` |
| `0000000303` | Customer `0000000107` |

The policy numbers and their dates are made up. The customers are two of the three that the customer-inquiry application is seeded with.

The outcomes, with proposed answers on the network:

| Outcome | When | Answer |
|---|---|---|
| `found` | The policy exists and its holder could be read | 200 |
| `not_found` | No policy has that number | 404 |
| `holder_unavailable` | The policy exists, and the owner of its holder cannot be reached | 503 |

`holder_unavailable` is a failure in the sense of rule 1.14. The store's own failures are as in the customer-inquiry application and are not repeated here.

## 3. Who owns what

| Entity type | Owner | Why |
|---|---|---|
| Policy | Policy inquiry | It works on the type and offers it through its service |
| Customer | Customer inquiry | It works on the type and offers it through its service. Policy inquiry only works on it, so it holds a reference |

This is the owner rule of the specification (section 6). The twin calculates it from the model; nothing in either application states it by hand.

One relationship crosses the two components:

| Kind | From | To | Navigable |
|---|---|---|---|
| Association | Policy, any number | Customer, exactly one, role `holder` | From the policy to the customer only |

The policy-inquiry component holds this relationship. The customer-inquiry component knows nothing of policies.

For its holder, a stored policy has two things and no more: the identifier of the owning component, `customer-inquiry`, and the identifier of the customer, which is the customer number. The holder's name is not stored with the policy. When `inquire_policy` builds its answer, it follows the relationship: an action key leads from its controller to the public operation `inquire_customer` of the customer-inquiry component, and the name in the answer is the one that operation returns at that moment.

## 4. Scenario

Both components are installed on one framework. Run in order.

| Step | What is done | Expected |
|---|---|---|
| 1 | Inquire policy `0000000301` | `found`. The answer names the holder: customer `0000000042`, with the first and last name that the customer-inquiry application holds |
| 2 | Look into the store of the policy-inquiry component | For its holder, policy `0000000301` holds `customer-inquiry` and `0000000042`. It holds no name and no other value of the customer |
| 3 | At the customer-inquiry component, change the last name of customer `0000000042`. Inquire policy `0000000301` again | `found`. The answer shows the new last name |
| 4 | Remove the customer-inquiry component. Inquire policy `0000000301` | `holder_unavailable`. Not `not_found`, and not `found` with an empty holder |
| 5 | With the customer-inquiry component still removed, inquire policy `0000000999`, which does not exist | `not_found`. The policy-inquiry component still answers, and still tells the two cases apart |
| 6 | Install the customer-inquiry component again. Inquire policy `0000000301` | `found`, with the holder's name |
| 7 | Remove the policy-inquiry component. Inquire customer `0000000042` at the customer-inquiry component | `found`. The owner does not depend on those who refer to its entities |

The customer-inquiry application has no operation that changes a customer. In step 3 the stored name is therefore changed at the owner by other means, as a test device. A caller that wants a customer changed asks the owner through a public operation (rule 2.1); the policy-inquiry component has no way to change it.

## 5. What the scenario covers

| What is shown | Rule | Steps |
|---|---|---|
| A flow from one component to a public operation of another | 2.4 | 1 |
| A relationship to an entity that another component owns; the owner and the identifier are stored, and no value | 2.14 | 2 |
| The values are the owner's: a change made at the owner is seen through the relationship | 2.1 | 3 |
| An owner that cannot be reached gives a failure, never "not found" | 2.14 | 4, 5 |
| A component is removed and installed while the other keeps answering | 2.3 | 4 to 7 |

Not covered, because the specification has not settled it (open decision 11): creating or deleting an entity across components, a customer that is deleted while a policy still names it, a copy of a customer kept by the policy-inquiry component, and finding policies by a value of their holder. Not covered either: the digital thread. In this revision the policy-inquiry component has no binding.

## 6. What is assumed

- The policy-inquiry application does not exist. GenApp has policy programs, and the demonstration did not take them over.
- The identifier of a customer is its customer number.
- No DAF model holds the two components yet. The owner rule of section 3 was applied by hand here, to show what the twin would calculate.
- The outcome name `holder_unavailable` and the three answers on the network.
- That removing a component is how "the owner cannot be reached" is shown. On two machines the same case arises when the network between them is down.
