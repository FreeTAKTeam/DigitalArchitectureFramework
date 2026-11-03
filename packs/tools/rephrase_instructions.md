# Rephrasing instructions for industry pack content

You rewrite reference architecture content for a DAF (Digital Architecture Framework) industry pack. The pack is *inspired by* an industry standard but must **not copy** it. You get a JSON batch file; you write a JSON result file.

## Input
A list of items. Each item has `key`, `kind` (what the element is in DAF), `source_name` and `source_text` (the source's description, may be empty). Some items also have:
- `numerator`, `denominator`, `formula`, `units` (key performance indicators): how the source computes the indicator.
- `attributes` (model classes): a list of `{key, source_name, source_text}`.
- `literals` (enumerations): a list of `{key, source_name}`.

## Output
A JSON list with one object per input item, in the same order:
`{"key": <same key>, "name": "...", "definition": "...", "attributes": [{"key": ..., "name": "...", "definition": "..."}], "literals": [{"key": ..., "name": "..."}]}`
Include `attributes` / `literals` only when the input item has them, with one entry per input entry, same keys and order.

## Rules for names
- A short noun phrase, Title Case, 1-5 words, that says what the element is or does. Style by kind:
  - business process, business service, application function: an action noun phrase ("Order Capture", "Fault Diagnosis").
  - parent application function: the group's subject plus "Functions" ("Billing Functions").
  - logical application component: the area plus "Application" ("Order Handling Application").
  - business capability: an ability ("Partner Onboarding").
  - data entity: the information area ("Customer Billing Information").
  - model class: a singular class noun phrase ("Billing Account").
  - key performance indicator: what is measured ("First Call Resolution Rate").
  - measurement group / category: the family of measures ("Service Quality Measures").
  - enumeration and datatype: a singular noun phrase ("Account State", "Time Interval").
- If the source name has **3 or more words, your name must differ from it** (synonyms, reordering, restating). Shorter names may stay when they are generic words ("Customer", "Money").
- Never use the words "ABE", "Aggregated Function", "TM Forum", "TMF", "SID", "eTOM", "TAM" or any numbering.
- Names must be unique within the batch for the same kind.

## Rules for definitions
- 1 or 2 plain sentences, at most 40 words, that say what the element is and what it is for. Start with "A process that", "A service that", "A function that", "A group of functions that", "An application that", "The ability to", "Information about", "A class that", "A measure of", "A set of measures", "A list of", "A value type for", as fits the kind.
- **Never copy the source text**: do not reuse any sequence of 5 or more consecutive words from `source_text`. Restate the meaning briefly in your own words.
- For a key performance indicator, say what is measured and, when a numerator/denominator or formula is given, how it is computed in your own words (e.g. "the share of orders completed on time among all orders completed").
- If `source_text` is empty, write the definition from the name and kind.
- Do not mention the source standard, identifiers or numbering.

## Attributes (model classes)
- `name`: lowerCamelCase, 1-4 words (`validPeriod`, `billingCycle`). If the source name has 3 or more words (counting camelCase parts), yours must differ. Generic names (`name`, `description`, `id`, `status`) may stay.
- `definition`: one short sentence, at most 20 words, no 5-word sequence copied from the source.

## Literals (enumerations)
- `name`: keep the source's style (case and separators). Generic values (`active`, `closed`, `yes`) may stay; a literal of 3 or more words must differ.

Write the result with the Write tool as valid JSON (UTF-8). Do not modify any other file.
