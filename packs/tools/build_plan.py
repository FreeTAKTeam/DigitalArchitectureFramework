"""Builds the EA write plan for a pack from model.json and rephrased.json (MAPPING.md, Structure).

usage: build_plan.py <local dir> <root package name> <pack key>
Writes plan.json: packages, elements (with attributes or literals), connectors. A parent with
children becomes a package of the same name holding the parent and its children. Elements whose
rephrasing failed are left out and listed in plan_report.json.
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

folder, root_name, pack_key = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
model = json.loads((folder / "model.json").read_text(encoding="utf-8"))
done = json.loads((folder / "rephrased.json").read_text(encoding="utf-8"))
E = {e["key"]: e for e in model["elements"] if e["key"] in done}
missing = [e for e in model["elements"] if e["key"] not in done]

REL_TYPE = {"dApplicationAggregatesFunction": "Aggregation", "dBizServUsesDataEntity": "Association",
            "dModelClassRealizesEntity": "Realisation", "dGroupAggregatesKPI": "Aggregation",
            "dCategoryaggregatesGroups": "Aggregation", "dModelClassAssociatesModelClass": "Association",
            "Generalization": "Generalization"}
PRIMITIVES = {"string": "String", "integer": "Integer", "int": "Integer", "boolean": "Boolean", "datetime": "DateTime",
              "date": "Date", "float": "Float", "double": "Float", "decimal": "Decimal", "long": "Int64",
              "unlimitednatural": "UnlimitedNatural", "uri": "URI", "url": "URI", "duration": "Duration"}
UNITS = {"%": "%", "percent": "%", "percentage": "%", "days": "d", "day": "d", "hours": "h", "hour": "h",
         "minutes": "min", "minute": "min", "seconds": "s", "second": "s", "count": "1", "number": "1", "ratio": "1"}


def name(key):
    return done[key]["name"]


def lower_camel(text):
    parts = re.findall(r"[A-Za-z0-9]+", text)
    return (parts[0].lower() + "".join(p[:1].upper() + p[1:] for p in parts[1:])) if parts else ""


# ---------------------------------------------------------------- packages
children = {}
for e in E.values():
    if e["parent"] in E:
        children.setdefault(e["parent"], []).append(e["key"])
packages = [{"key": "root", "name": root_name, "parent": None}]
domains = sorted({e["domain"] for e in E.values()})
for d in domains:
    packages.append({"key": "d:" + d, "name": d, "parent": "root"})
placed = {}


def place(key, pkg):
    if key in children:
        pk = "p:" + key
        packages.append({"key": pk, "name": name(key), "parent": pkg})
        placed[key] = pk
        for c in sorted(children[key], key=name):
            place(c, pk)
    else:
        placed[key] = pkg


for e in sorted(E.values(), key=lambda e: name(e["key"])):
    if e["parent"] not in E:
        place(e["key"], "d:" + e["domain"])

# ---------------------------------------------------------------- elements
types_by_source_name = {e["sourceName"].lower(): e["key"] for e in E.values() if e["type"] in ("Enumeration", "DataType")}
report = {"rephrasing failed": [e["sourceName"] for e in missing], "attribute type not resolved": []}
plan_elements = []
for e in E.values():
    r = done[e["key"]]
    item = {"sourceGuid": e["key"], "package": placed[e["key"]], "type": e["type"],
            "stereotype": ("DAF::" + e["stereotype"]) if e["stereotype"] else None,
            "name": r["name"], "notes": r["definition"], "tags": {"pack": pack_key, "inspiredBy": e["inspiredBy"]}}
    if e["stereotype"] in ("dMeasurementIndicator", "dMeasurementGrouping", "dMeasurementCategory"):
        item["tags"]["Definition"] = r["definition"]
    units = (e["extra"].get("units") or "").strip()
    if units and e["stereotype"] == "dMeasurementIndicator":
        item["tags"]["UnitOfMeasure"] = UNITS.get(units.lower(), units)
    if e.get("attributes"):
        attrs = []
        for a in e["attributes"]:
            ra = r["attributes"][a["key"]]
            tkey = a["classifier"] if a["classifier"] in E else types_by_source_name.get((a["type"] or "").lower())
            if tkey:
                tname = name(tkey)
            else:
                tname = PRIMITIVES.get((a["type"] or "").lower(), "")
                if not tname:
                    report["attribute type not resolved"].append(f"{e['sourceName']}.{a['sourceName']}: {a['type']}")
            attrs.append({"sourceGuid": a["key"], "name": ra["name"], "notes": ra["definition"], "type": tname,
                          "classifier": tkey, "lower": a["lower"] or "1", "upper": a["upper"] or "1",
                          "visibility": a["visibility"] or "Public", "isStatic": bool(a["isStatic"]),
                          "isConst": bool(a["isConst"]), "isOrdered": bool(a["isOrdered"]), "pos": a["pos"] or 0})
        item["attributes"] = attrs
    if e.get("literals"):
        item["literals"] = [{"sourceGuid": l["key"], "name": r["literals"][l["key"]]} for l in e["literals"]]
    plan_elements.append(item)
# types first, so attribute classifiers exist when attributes are written
plan_elements.sort(key=lambda x: (x["type"] not in ("Enumeration", "DataType"), x["package"], x["name"]))

# ---------------------------------------------------------------- connectors
connectors, seen = [], set()
for l in model["links"]:
    if l["source"] not in E or l["target"] not in E:
        continue
    sig = (l["rel"], l["source"], l["target"])
    if sig in seen and l["rel"] != "dModelClassAssociatesModelClass":
        continue
    seen.add(sig)
    c = {"source": l["source"], "target": l["target"], "type": REL_TYPE[l["rel"]],
         "stereotype": None if l["rel"] == "Generalization" else "DAF::" + l["rel"]}
    if "ends" in l:
        ends = l["ends"]
        c["ends"] = {"sourceCard": ends["sourceCard"] or "", "targetCard": ends["targetCard"] or "",
                     "sourceNavigable": bool(ends["sourceNavigable"]), "targetNavigable": bool(ends["targetNavigable"]),
                     "sourceAggregation": ends["sourceAggregation"] or 0, "targetAggregation": ends["targetAggregation"] or 0,
                     "sourceRole": lower_camel(name(l["source"])), "targetRole": lower_camel(name(l["target"]))}
    connectors.append(c)

plan = {"packages": packages, "elements": plan_elements, "connectors": connectors}
(folder / "plan.json").write_text(json.dumps(plan, ensure_ascii=False, indent=1), encoding="utf-8")
(folder / "plan_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")
print(f"packages {len(packages)}, elements {len(plan_elements)}, attributes "
      f"{sum(len(e.get('attributes', [])) for e in plan_elements)}, connectors {len(connectors)}")
print("by stereotype:", Counter(e["stereotype"] or e["type"] for e in plan_elements))
print({k: len(v) for k, v in report.items()})
