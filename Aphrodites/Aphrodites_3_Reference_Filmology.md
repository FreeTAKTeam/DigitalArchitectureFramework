# Aphrodites 3.0: reference application "Filmology", revision 2

**Status:** revision 2, 26 November 2026. It adds three cases to revision 1, so that every rule of step 1 can be decided: a value reference, an action key and a rule that makes two changes. They are steps 15 to 20 of the scenario; steps 1 to 14 are unchanged. The three cases have not been run.

**History:** revision 1 was approved by the owner on 24 November 2026 as the reference for a generator. It changes the source model in five places. The approved input a generator runs from is not written yet.

**Source:** the Filmology example in DigitalPy (`examples/filmology_app`, commit `910745e`), read from its OpenAPI model.

## 1. What it is for

Filmology is the reference for a generator. A generator shows that it fits by producing this component from this model and by the component passing the scenario of section 6 on a framework at step 1.

A framework shows conformance by the checks listed under each step of the specification (`Aphrodites_3_Specification.md`). Running Filmology is the first check of step 1, because it is the simplest way to show a generated application running. The other checks use small models of their own.

## 2. Changes from the source model

| # | Source model | Revision 1 | Why |
|---|---|---|---|
| 1 | The kind of each relationship is only in its name | Each relationship states its kind | A generator must not read meaning from a name |
| 2 | "CompositionActor" links many movies to many actors | A plain association between Movie and Actor | A composition cannot have many owners |
| 3 | Every value is text | The year is a four-digit whole number; the runtime is a whole number of minutes | To exercise typed values and a restriction |
| 4 | One link between Date and Movie | Two: release date and premiere date | To exercise two roles between the same two types |
| 5 | No business rule | One production rule, section 5 | To exercise rules |

Also: Movie's own text value `date` is dropped, because the release date is the relationship. Three duplicate relationships of the source model, with unspecified navigability, are left out.

Added in revision 2:

| # | Added | Why |
|---|---|---|
| 6 | The value reference `directorName` on Movie | To exercise a value reference |
| 7 | One action key from MovieController to CatalogueController, and the operation that uses it | To exercise an action between controllers |
| 8 | A second rule that makes two changes, and a limit on the length of `alias` | To exercise a rule whose changes are kept together or not at all |

## 3. Entity types

| Entity type | Extends | Abstract | Own values |
|---|---|---|---|
| EntityBase | Nothing | Yes | `created`, read-only; `creator`, read-only; `lastEditor`; `modified` |
| EntityBaseExtended | EntityBase | Yes | `name`; `description` |
| Person | EntityBaseExtended | Yes | `surname`; `birth`; `nationality` |
| Image | Nothing | Yes | `fileName` |
| Movie | EntityBaseExtended | No | `alias`, at most 20 characters; `color`; `country`; `URL`; `plot`; `runtime`, a whole number; `directorName`, a value reference that shows the `name` of the movie's director |
| Poster | Image | No | None |
| Date | Nothing | No | `year`, a whole number that must match four digits |
| Director | Person | No | None |
| Actor | Person | No | None |

Values are text unless stated. Genre, Language and Error of the source model are left out. The default values are those of the model; this revision does not fix them yet. The default year has to be a four-digit number. The default runtime is not from 1 to 39, so that the second rule of section 5 does not apply to it.

## 4. Relationships

| # | Kind | Parent end | Child end | Navigable |
|---|---|---|---|---|
| R1 | Composition | Movie, exactly one, role `movie` | Poster, exactly one, role `primaryPoster` | Both ways |
| R2 | Aggregation | Date, exactly one, role `releaseDate` | Movie, any number, role `released` | Both ways |
| R3 | Aggregation | Date, at most one, role `premiereDate` | Movie, any number, role `premiered` | Both ways |
| R4 | Aggregation | Director, exactly one, role `director` | Movie, any number, role `movies` | Both ways |

| # | Kind | One end | Other end | Navigable |
|---|---|---|---|---|
| R5 | Association | Movie, any number, role `appearsIn` | Actor, any number, role `cast` | Both ways |

R5 has no parent and no child: a movie's actors are its associated entities.

A movie needs exactly one primary poster, one release date and one director. All three are there from the moment the movie is created: as given, or else by default (specification, rule 1.7). The application then offers to add a poster, and to select a release date and a director.

## 5. Controllers, operations and the rule

| Controller | Public operations |
|---|---|
| MovieController | Create, read, update and delete a movie; add an actor to a movie's cast; remove one; set and clear a movie's premiere date; read the director of a movie (`read_movie_director`) |
| CatalogueController | Create, read, update and delete a date, a director and an actor |

One action key, from MovieController to CatalogueController:

| Property | Value |
|---|---|
| `action` | `read_director` |
| `context` | Empty, so it fits any |
| `method` | Empty, so the method with the action's name runs: `read_director` of CatalogueController |

The method of `read_movie_director` reads the movie and then raises the action `read_director` for the movie's director. It does not read the director itself.

Two rules, owned by MovieController. The first:

| Field | Value |
|---|---|
| Binding key | `silent_era_color` |
| Kind | Production |
| Statement | When a movie is created or its release date changes: if the year of its release date is before 1930 and its color is empty, set its color to "black and white". |
| Reads | The movie and its release date |
| May change | The movie |

The second, which makes two changes:

| Field | Value |
|---|---|
| Binding key | `short_film_label` |
| Kind | Production |
| Statement | When a movie is created or its runtime changes: if its runtime is from 1 to 39 minutes, set its description to "short film" and set its alias to its name followed by " (short)". |
| Reads | The movie |
| May change | The movie |

## 6. Scenario

Run in order on an empty store. Names are placeholders.

| Step | What is done | Expected |
|---|---|---|
| 1 | Create a date with year 1927 | Stored as D1 |
| 2 | Create a date with year 927 | Refused as invalid input, because the year must have four digits; nothing stored |
| 3 | Create a director named "Director One" | Stored as P1 |
| 4 | Create a movie "Film One" with empty color, a primary poster "film-one.png", release date D1 and director P1 | Stored as M1 with color "black and white"; a poster PO1 is stored, owned by M1 |
| 5 | Create a movie "Film X" with nothing but its name; then delete it | Stored, with a poster, a release date and a director that have default values. After the delete the movie and its poster are gone; the default date and director remain |
| 6 | Create an actor "Actor One"; add it to M1's cast | Stored as A1; M1's cast is A1; A1 appears in M1 |
| 7 | Create a date with year 1984; create a movie "Film Two" with color "color", a poster, that release date and director P1 | Stored as D2 and M2; M2's color stays "color" |
| 8 | Read the movies of director P1 | M1 and M2 |
| 9 | Delete director P1 | Refused; P1, M1 and M2 remain |
| 10 | Set M2's premiere date to D1; read the movies released on D1 and those premiered on D1 | Released: M1 only. Premiered: M2 only. The two roles are kept apart |
| 11 | Change M2's release date to D1; read the movies released on D1 | Stored; M2's color stays "color", because it is not empty. Released on D1: M1 and M2 |
| 12 | Detach PO1 from M1 | Refused |
| 13 | Delete M1 | M1 and PO1 are gone; D1, P1 and A1 remain; A1 appears in no movie |
| 14 | Read M1 | A result with the outcome "not found" |
| 15 | Read M2 | Its `directorName` is "Director One" |
| 16 | Set the `directorName` of M2 to "Someone Else" | Refused; M2 and P1 are unchanged |
| 17 | Call `read_movie_director` for M2 | Director P1, as `read_director` of CatalogueController gives it |
| 18 | Change M2's runtime to 30 | Stored; M2's description is "short film" and its alias is "Film Two (short)" |
| 19 | Create a movie "The Longest Film Name" with an empty description, an empty alias, a poster, release date D2 and director P1 | Stored as M3; its description and its alias are empty |
| 20 | Change M3's runtime to 30 | The alias would have 29 characters, so that change is refused. Neither change of the rule is kept: M3's description and alias are still empty |

Rule 1.19 does not say whether the runtime change of step 20 is itself stored. Write down what the framework does.

## 7. What the scenario covers

| Feature | Steps |
|---|---|
| Typed value and restriction | 1, 2 |
| Everything a movie needs is created with it, given or by default | 4, 5 |
| Composition: created through the parent, deleted with it, not detachable | 4, 12, 13 |
| Aggregation: children survive; a delete that would break a minimum is refused | 9, 13 |
| Many-to-many association | 6, 13 |
| Two roles between the same types | 10 |
| Inheritance: a director and an actor have the name they inherit | 3, 6 |
| Production rule: applied, and not applied | 4, 7, 11 |
| Generated create, read, update, delete | 1, 3, 4, 8, 13 |
| "Not found" as an outcome | 14 |
| Value reference: shown, and cannot be set | 15, 16 |
| Action from one controller to another, by an action key | 17 |
| A rule with two changes: both kept, or neither | 18, 19, 20 |

Not covered: abstract types, read-only values, events, settings and access. The checks of steps 1 and 2 in the specification cover most of them.
