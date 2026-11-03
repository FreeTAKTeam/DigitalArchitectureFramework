"""Complete the DAF measurement hierarchy of an exported pack TTL.

DAF requires every dMeasurementCategory to sit in exactly one
dMeasurementArea (dAreaAggregatesCategories, source 1) and every
dMeasurementIndicator in at least one dMeasurementGrouping
(dGroupAggregatesKPI, source 1..*). The Telecom pack 1.0.0 export has no
area and 570 KPIs without a group. This appends, in the M1 exporter's own
form:

  - one area that aggregates every category;
  - one generic category, under that area, holding one generic grouping
    (a grouping must belong to exactly one category);
  - links from the generic grouping to every KPI without a group.

New resources have no EA GUID: they exist only in the TTL until they are
added in EA. Their IRIs are uuid5 of fixed names, so a rerun is a no-op.

Usage: python3 fix_measurement_hierarchy.py <pack.ttl> <area name>
"""

import re
import sys
import uuid
from pathlib import Path

MARKER = "# Measurement hierarchy completed by packs/tools/fix_measurement_hierarchy.py"
NS = uuid.UUID("6d1f3c2a-8f4e-4b1a-9c7e-2a5b8d0e4f61")


def lit(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def iri(kind, name):
    return f"m:{kind}_" + str(uuid.uuid5(NS, name)).replace("-", "_")


def elements_of(text, daf_type):
    return re.findall(rf"^(m:element_\w+)\n    a daf:{daf_type} ;", text, re.M)


def targets_of(text, rel):
    return set(re.findall(rf"dafrel:{rel} ;\n    dafm:relationshipType \S+ ;\n    dafm:source \S+ ;\n    dafm:target (\S+) ;", text))


def package_of(text, element):
    m = re.search(rf"^{re.escape(element)}\n(?:    .*\n)*?    dafi:containedInPackage (\S+) ;", text, re.M)
    return m.group(1)


def element(e, daf_type, name, notes, package, pack, inspired):
    eid = e.split("_", 1)[1].replace("_", "-")
    return f"""# Element: {name} [{daf_type} -> {daf_type}]
{e}
    a daf:{daf_type} ;
    dafp:id {lit(eid)}^^xsd:string ;
    dafp:name {lit(name)} ;
    dafp:stereotype {lit(daf_type)} ;
    dafp:modelType "Class" ;
    dafi:sourceElementType "Class" ;
    dafi:containedInPackage {package} ;
    dafp:notes {lit(notes)} ;
    dafp:status "Proposed" ;
    dcterms:source "packs/tools/fix_measurement_hierarchy.py" ;
    dafm:sourceStereotype {lit(daf_type)} .

{e} dafp:{daf_type}__Definition {lit(notes)} .
{e} dafp:pack {lit(pack)} .
{e} dafp:inspiredBy {lit(inspired)} .

"""


def link(rel, source, target):
    r = iri("relationship", f"{rel}|{source}|{target}")
    return f"""# Relationship:
{r}
    a dafm:Relationship, dafrel:{rel} ;
    dafm:relationshipType dafrel:{rel} ;
    dafm:source {source} ;
    dafm:target {target} ;
    dafi:relationshipResolution "exact-stereotype" ;
    dafi:semanticDirectionReversed "false"^^xsd:boolean ;
    dcterms:source "packs/tools/fix_measurement_hierarchy.py" ;
    dafm:sourceStereotype {lit(rel)} .

{source} dafpred:{rel} {target} .
{target} dafpred:{rel}_inverse {source} .

"""


def check(text):
    """Every category has an area and every KPI a group; returns the gaps."""
    with_area = targets_of(text, "dAreaAggregatesCategories")
    with_group = targets_of(text, "dGroupAggregatesKPI")
    return ([c for c in elements_of(text, "dMeasurementCategory") if c not in with_area],
            [k for k in elements_of(text, "dMeasurementIndicator") if k not in with_group])


def main(path, area_name):
    text = path.read_text(encoding="utf-8")
    if MARKER in text:
        print("already applied")
        return
    pack = re.search(r'dafp:pack "([^"]+)"', text).group(1)
    inspired = "business metrics"
    categories = elements_of(text, "dMeasurementCategory")
    _, ungrouped = check(text)
    # New elements go where the ungrouped KPIs already are (the metrics root package).
    package = package_of(text, ungrouped[0] if ungrouped else categories[0])

    area = iri("element", f"{pack}|area|{area_name}")
    out = [f"\n{MARKER}\n\n",
           element(area, "dMeasurementArea", area_name,
                   "The area that holds every measurement category of the telecom pack.",
                   package, pack, inspired)]
    out += [link("dAreaAggregatesCategories", area, c) for c in categories]
    if ungrouped:
        cat = iri("element", f"{pack}|category|General Measures")
        grp = iri("element", f"{pack}|grouping|Unclassified Measures")
        out.append(element(cat, "dMeasurementCategory", "General Measures",
                           "A category for measures that the source frameworks do not place in any group.",
                           package, pack, inspired))
        out.append(element(grp, "dMeasurementGrouping", "Unclassified Measures",
                           "A set of measures that the source frameworks do not place in any group. Each still needs a proper grouping.",
                           package, pack, inspired))
        out.append(link("dAreaAggregatesCategories", area, cat))
        out.append(link("dCategoryaggregatesGroups", cat, grp))
        out += [link("dGroupAggregatesKPI", grp, k) for k in ungrouped]
    text += "".join(out)

    no_area, no_group = check(text)
    assert not no_area and not no_group, (len(no_area), len(no_group))
    path.write_text(text, encoding="utf-8")
    print(f"area 1 -> {len(categories) + bool(ungrouped)} categories; "
          f"{len(ungrouped)} KPIs -> 'Unclassified Measures'")


if __name__ == "__main__":
    main(Path(sys.argv[1]), sys.argv[2])
