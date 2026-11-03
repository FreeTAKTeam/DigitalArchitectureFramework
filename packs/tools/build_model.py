"""Applies the telecom pack mapping (packs/telecom/MAPPING.md) to the raw source extract.

usage: build_model.py <local dir> [batch size]
Reads <local dir>/raw/raw_*.json (extract_source.ps1). Writes:
  model.json       elements, attributes, links and package placement, keyed by source GUID
  batches/b_NNN.json  rephrasing input, one file per Haiku agent
  report.json      everything left out, with the reason
"""
import html
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

folder = Path(sys.argv[1])
BATCH = int(sys.argv[2]) if len(sys.argv) > 2 else 100
raw = {n: json.loads((folder / "raw" / f"raw_{n}.json").read_text(encoding="utf-8"))
       for n in ("packages", "objects", "tags", "attributes", "connectors")}
P = {p["id"]: p for p in raw["packages"]}
O = {o["id"]: o for o in raw["objects"]}
tags = defaultdict(dict)
for t in raw["tags"]:
    value = t["notes"] if t["value"] == "<memo>" else t["value"]
    tags[t["id"]].setdefault(t["name"], value)
report = []


def left_out(o, reason):
    report.append({"guid": o["guid"], "stereotype": o["stereotype"] or o["type"], "name": o["name"],
                   "package": P[o["package"]]["path"], "reason": reason})


def clean(text):
    text = html.unescape(re.sub(r"<[^>]+>", " ", text or ""))
    return re.sub(r"\s+", " ", text).strip()


def tag(oid, *names):
    for n in names:
        v = tags[oid].get(n)
        if v not in (None, ""):
            return v
    return None


def why_out(o):
    path = P[o["package"]]["path"]
    if "Deleted" in path or (tag(o["id"], "isDeleted", "is Deleted") or "").lower() == "true":
        return "deleted in the source"
    if "UNUSED" in path:
        return "marked unused in the source"
    if "MODA Help" in path:
        return "help example, not reference content"
    return None


def live(o):
    return why_out(o) is None


# ---------------------------------------------------------------- domains
DOMAIN_NAMES = {  # source domain or capability package -> pack domain package
    "Business Partner Domain": "Business Partner", "Partner": "Business Partner",
    "Common Domain": "Common", "Customer Domain": "Customer", "Customer": "Customer",
    "Enterprise Domain": "Enterprise", "Enterprise": "Enterprise",
    "Integration Domain": "Integration", "Market & Sales Domain": "Market and Sales",
    "Market": "Market and Sales", "Sales": "Market and Sales",
    "Product Domain": "Product", "Product": "Product", "Resource Domain": "Resource", "Resource": "Resource",
    "Service Domain": "Service", "Service": "Service", "Shared Domain": "Shared",
}
OTHER = "Cross-Domain"
domain_objs = {o["id"]: o for o in O.values() if o["stereotype"] == "TMF_Domain"}

# ---------------------------------------------------------------- connectors
by_st = defaultdict(list)
for k in raw["connectors"]:
    if k["source"] in O and k["target"] in O:
        by_st[k["stereotype"] or "(" + k["type"] + ")"].append(k)


def st(oid):
    return O[oid]["stereotype"] if oid in O else None


KIND = {  # source stereotype -> (kind label for the rephraser, EA type, DAF stereotype, inspiredBy)
    "TMF_Process": None,  # by level and ABE links
    "TMF_Application": ("logical application component", "Component", "dLogicalAppComponent", "application map"),
    "TMF_Function": ("application function", "Class", "dApplicationFunction", "application map"),
    "TMF_AF": ("parent application function (groups functions)", "Class", "dApplicationFunction", "application map"),
    "TMF_ABE": ("data entity (a group of related business information)", "Class", "dDataEntity", "information framework"),
    "TMF_BusinessEntity": ("model class (a business information class with attributes)", "Class", "dModelClass", "information framework"),
    "TMF_Capability": ("business capability", "Class", "dCapability", "business capability map"),
    "TMF_Metric": ("key performance indicator", "Class", "dMeasurementIndicator", "business metrics"),
}
PROCESS = ("business process", "Class", "dBusinessProcess", "process framework")
SERVICE = ("business service (a fine-grained business activity)", "Activity", "dBusinessService", "process framework")
CATEGORY = ("measurement category (a top-level family of KPIs)", "Class", "dMeasurementCategory", "business metrics")
GROUPING = ("measurement group (a set of related KPIs)", "Class", "dMeasurementGrouping", "business metrics")

elements = {}  # source object id -> element record


def add(o, kind):
    label, etype, stereo, inspired = kind
    elements[o["id"]] = {"key": o["guid"], "oid": o["id"], "source": o["stereotype"], "kind": label, "type": etype,
                         "stereotype": stereo, "inspiredBy": inspired, "sourceName": o["name"].strip(),
                         "sourceText": clean(o["note"]), "parent": None, "domain": None, "extra": {}}


for o in O.values():
    s = o["stereotype"]
    if s in KIND and s != "TMF_Process":
        if live(o):
            add(o, KIND[s])
        else:
            left_out(o, why_out(o))
    elif s in ("TMF_Vertical",):
        left_out(o, "verticals are dropped")
    elif s in ("TMF_JSON_Schema", "TMF_JSON_Element", "TMF_API"):
        left_out(o, "schema and API slices are deferred")
    elif s in ("TMF_ISC", "TMF_IIC"):
        left_out(o, "unmapped stereotype")

# capability and process text often lives in tags, not notes
for e in elements.values():
    if not e["sourceText"]:
        e["sourceText"] = clean(tag(e["oid"], "BriefDescription", "TMF::BriefDescription", "ShortDescription",
                                    "brief description", "Definition") or "")


# ---------------------------------------------------------------- processes
proc = {o["id"]: o for o in O.values() if o["stereotype"] == "TMF_Process" and live(o)}
for o in O.values():
    if o["stereotype"] == "TMF_Process" and o["id"] not in proc:
        left_out(o, why_out(o))
proc_parent = {}
for k in by_st["TMF_isComposedByProcess"]:
    if k["source"] in proc and k["target"] in proc:
        proc_parent.setdefault(k["source"], k["target"])
level = {}
for pid in proc:
    v = tag(pid, "HierarchyLevel", "TMF::HierarchyLevel", "Level")
    if v and str(v).strip().isdigit():
        level[pid] = int(str(v).strip())


def derive_level(pid, seen=()):
    if pid in level:
        return level[pid]
    par = proc_parent.get(pid)
    if par is None or par in seen:
        return None
    lv = derive_level(par, seen + (pid,))
    return None if lv is None else lv + 1


abe_ids = {oid for oid, e in elements.items() if e["source"] == "TMF_ABE"}
proc_abe = defaultdict(set)
for name in ("TMF_ProcessProducesABE", "TMF_MakesUseOfABE", "(Dependency)"):
    for k in by_st[name]:
        if k["source"] in proc and k["target"] in abe_ids:
            proc_abe[k["source"]].add(k["target"])
derived = 0
for pid, o in proc.items():
    lv = derive_level(pid)
    if lv is None:
        left_out(o, "process level unknown, also from the process structure")
        continue
    if pid not in level:
        derived += 1
    add(o, SERVICE if (lv >= 4 or proc_abe[pid]) else PROCESS)
    elements[pid]["extra"]["level"] = lv
    if not elements[pid]["sourceText"]:
        elements[pid]["sourceText"] = clean(tag(pid, "BriefDescription", "TMF::BriefDescription", "brief description") or "")


# ---------------------------------------------------------------- hierarchy (child -> parent) and domains
def set_parent(child, parent):
    if child in elements and parent in elements and elements[child]["parent"] is None and child != parent:
        elements[child]["parent"] = parent


for name in ("TMF_isComposedByProcess", "TMF_ApplicationComposedApplication", "TMF_AFAggregatesAF",
             "TMF_AFAggregatesFunction", "TMF_ABECompositedOfABE"):
    for k in by_st[name]:
        set_parent(k["source"], k["target"])
for k in by_st["TMF_DomainAggregatesFunction"]:  # a function placed under a parent function
    if st(k["target"]) == "TMF_AF":
        set_parent(k["source"], k["target"])
for k in by_st["(Aggregation)"]:  # unstereotyped application nesting
    if st(k["source"]) == st(k["target"]) == "TMF_Application":
        set_parent(k["source"], k["target"])

# break cycles
for oid in list(elements):
    seen, cur = set(), oid
    while elements[cur]["parent"] is not None:
        if cur in seen:
            elements[cur]["parent"] = None
            break
        seen.add(cur)
        cur = elements[cur]["parent"]

for k in raw["connectors"]:
    if k["target"] in domain_objs and k["source"] in elements and k["type"] == "Aggregation":
        elements[k["source"]].setdefault("ownDomain", DOMAIN_NAMES.get(domain_objs[k["target"]]["name"], OTHER))
for e in elements.values():
    if e["source"] == "TMF_Capability":
        e["ownDomain"] = DOMAIN_NAMES.get(P[O[e["oid"]]["package"]]["name"], OTHER)


def path_domain(oid):
    """Fallback: the domain named in the source package path, e.g. .../Service Domain/..."""
    for seg in reversed(P[O[oid]["package"]]["path"].split("/")):
        seg = seg.replace("Market Sales", "Market & Sales")
        if seg in DOMAIN_NAMES and seg.endswith("Domain"):
            return DOMAIN_NAMES[seg]
    return None


def root(oid):
    while elements[oid]["parent"] is not None:
        oid = elements[oid]["parent"]
    return oid


conflicts = 0
for oid, e in elements.items():
    if e["source"] in ("TMF_Metric",):
        continue
    r = elements[root(oid)]
    e["domain"] = r.get("ownDomain") or path_domain(r["oid"]) or OTHER
    if e.get("ownDomain") and e["ownDomain"] != e["domain"]:
        conflicts += 1

# entities: placed in their (first) ABE
realizes = []
for k in by_st["TMF_ABEIsComposedByEntity"]:
    if st(k["source"]) == "TMF_BusinessEntity" and k["source"] in elements and k["target"] in elements \
            and st(k["target"]) == "TMF_ABE":
        realizes.append((k["source"], k["target"]))
        set_parent(k["source"], k["target"])
for oid, e in elements.items():
    if e["source"] == "TMF_BusinessEntity":
        r = elements[root(oid)]
        e["domain"] = r.get("ownDomain") or r["domain"] or path_domain(r["oid"]) or OTHER

# ---------------------------------------------------------------- metrics
metrics = {oid for oid, e in elements.items() if e["source"] == "TMF_Metric"}
groups = {o["id"]: o for o in O.values() if o["stereotype"] == "TMF_MetricGroup"}
group_parent = {}
for k in by_st["TMF_MetricGroupComposedOfMetricGroup"]:
    if k["source"] in groups and k["target"] in groups:
        group_parent.setdefault(k["source"], k["target"])


def top(g):
    seen = set()
    while g in group_parent and g not in seen:
        seen.add(g)
        g = group_parent[g]
    return g


kpi_group = defaultdict(set)
for k in by_st["TMF_MetricGroupMetric"]:
    if k["source"] in metrics and k["target"] in groups:
        kpi_group[k["target"]].add(k["source"])
kept_groups = {g for g in groups if kpi_group[g]}
for g, o in groups.items():
    if g not in kept_groups and top(g) != g:
        left_out(o, "metric group without a metric")
categories = {top(g) for g in kept_groups}
for c in categories:
    add(groups[c], CATEGORY)
    elements[c]["domain"] = "Business Metrics"
for g in kept_groups:
    gkey = ("grp", g)
    o = groups[g]
    label, etype, stereo, inspired = GROUPING
    elements[gkey] = {"key": o["guid"] + "#group" if g in categories else o["guid"], "oid": g, "source": "TMF_MetricGroup",
                      "kind": label, "type": etype, "stereotype": stereo, "inspiredBy": inspired,
                      "sourceName": o["name"].strip(), "sourceText": clean(o["note"]), "parent": top(g),
                      "domain": "Business Metrics", "extra": {}}
placed_kpi = set()
for g in kept_groups:
    for m in sorted(kpi_group[g]):
        if m not in placed_kpi:
            elements[m]["parent"] = ("grp", g)
            placed_kpi.add(m)
for m in metrics:
    elements[m]["domain"] = "Business Metrics"
    num = [O[k["target"]]["name"] for k in by_st["TMF_MetricNumenator"] if k["source"] == m and k["target"] in O]
    den = [O[k["target"]]["name"] for k in by_st["TMF_MetricDenominator"] if k["source"] == m and k["target"] in O]
    e = elements[m]
    e["extra"].update({k: v for k, v in (("numerator", num), ("denominator", den),
                                          ("formula", clean(tag(m, "txtformula") or "")),
                                          ("units", tag(m, "units", "UnitOfMeasure"))) if v})

# ---------------------------------------------------------------- attributes, datatypes, enumerations
attrs_by_owner = defaultdict(list)
for a in raw["attributes"]:
    attrs_by_owner[a["owner"]].append(a)
used_types = set()
for oid, e in elements.items():
    if e["source"] != "TMF_BusinessEntity":
        continue
    e["attributes"] = []
    for a in sorted(attrs_by_owner[e["oid"]], key=lambda a: (a["pos"] or 0)):
        cid = int(a["classifier"]) if a["classifier"] and str(a["classifier"]).isdigit() else 0
        if cid in O and O[cid]["type"] in ("DataType", "Enumeration"):
            used_types.add(cid)
        e["attributes"].append({"key": a["guid"], "sourceName": a["name"], "sourceText": clean(a["notes"]),
                                "type": a["type"], "classifier": O[cid]["guid"] if cid in O else None,
                                "lower": a["lower"], "upper": a["upper"], "visibility": a["visibility"],
                                "isStatic": a["isStatic"], "isConst": a["isConst"], "isOrdered": a["isOrdered"],
                                "pos": a["pos"]})
for cid in used_types:
    o = O[cid]
    is_enum = o["type"] == "Enumeration"
    elements[cid] = {"key": o["guid"], "oid": cid, "source": o["type"],
                     "kind": "enumeration (a list of allowed values)" if is_enum else "datatype (a structured value type)",
                     "type": o["type"], "stereotype": None, "inspiredBy": "information framework",
                     "sourceName": o["name"].strip(), "sourceText": clean(o["note"]), "parent": None,
                     "domain": "Information Types", "extra": {}}
    if is_enum:
        elements[cid]["literals"] = [{"key": a["guid"], "sourceName": a["name"]}
                                     for a in sorted(attrs_by_owner[cid], key=lambda a: (a["pos"] or 0))]
for o in O.values():
    if o["type"] in ("Enumeration", "DataType") and o["id"] not in used_types:
        left_out(o, "type not used by any model class attribute")

# ---------------------------------------------------------------- relationships
links = []


def link(rel, s, t, extra=None):
    if s in elements and t in elements:
        links.append({"rel": rel, "source": elements[s]["key"], "target": elements[t]["key"], **(extra or {})})


for k in by_st["TMF_ApplicationAssociatesFunction"]:
    link("dApplicationAggregatesFunction", k["source"], k["target"])
for pid, abes in proc_abe.items():
    for a in abes:
        if pid in elements and elements[pid]["stereotype"] == "dBusinessService":
            link("dBizServUsesDataEntity", pid, a)
for s, t in realizes:
    link("dModelClassRealizesEntity", s, t)
for g in kept_groups:
    for m in kpi_group[g]:
        if ("grp", g) in elements and m in elements:
            links.append({"rel": "dGroupAggregatesKPI", "source": elements[("grp", g)]["key"], "target": elements[m]["key"]})
    if top(g) in elements:
        links.append({"rel": "dCategoryaggregatesGroups", "source": elements[top(g)]["key"], "target": elements[("grp", g)]["key"]})
entities = {oid for oid, e in elements.items() if e["source"] == "TMF_BusinessEntity"}
for k in raw["connectors"]:
    if k["source"] in entities and k["target"] in entities:
        if k["type"] in ("Association", "Aggregation") and k["stereotype"] != "doNotImplement":
            link("dModelClassAssociatesModelClass", k["source"], k["target"], {
                "ends": {f: k[f] for f in ("sourceCard", "targetCard", "sourceNavigable", "targetNavigable",
                                           "sourceAggregation", "targetAggregation", "direction")}})
        elif k["type"] == "Generalization":
            link("Generalization", k["source"], k["target"])

# ---------------------------------------------------------------- output
out_elements = []
for oid, e in elements.items():
    par = e["parent"]
    e = {k: v for k, v in e.items() if k not in ("oid", "ownDomain")}
    e["parent"] = elements[par]["key"] if par is not None and par in elements else None
    out_elements.append(e)
model = {"elements": out_elements, "links": links}
(folder / "model.json").write_text(json.dumps(model, ensure_ascii=False, indent=1), encoding="utf-8")
(folder / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")

# rephrasing batches: same kind together; entities in smaller batches because they carry attributes
bdir = folder / "batches"
bdir.mkdir(exist_ok=True)
for f in bdir.glob("b_*.json"):
    f.unlink()
done_path = folder / "rephrased.json"  # results kept from earlier runs (e.g. the pilot), keyed by source GUID
done = json.loads(done_path.read_text(encoding="utf-8")) if done_path.exists() else {}
items = []
for e in out_elements:
    if e["key"] in done:
        continue
    it = {"key": e["key"], "kind": e["kind"], "source_name": e["sourceName"], "source_text": e["sourceText"][:1200]}
    for k in ("numerator", "denominator", "formula", "units"):
        if k in e["extra"]:
            it[k] = e["extra"][k]
    if e.get("attributes"):
        it["attributes"] = [{"key": a["key"], "source_name": a["sourceName"], "source_text": a["sourceText"][:300]}
                            for a in e["attributes"]]
    if e.get("literals"):
        it["literals"] = [{"key": l["key"], "source_name": l["sourceName"]} for l in e["literals"]]
    items.append((e["domain"] or OTHER, e["kind"], e["sourceName"], it))
items.sort(key=lambda x: (x[1], x[0], x[2]))
n, cur, cur_kind, weight = 0, [], None, 0


def flush():
    global n, cur, weight
    if cur:
        n += 1
        (bdir / f"b_{n:03d}.json").write_text(json.dumps(cur, ensure_ascii=False, indent=1), encoding="utf-8")
    cur, weight = [], 0


for _, kind, _, it in items:
    w = 1 + len(it.get("attributes", [])) / 2 + len(it.get("literals", [])) / 6
    if cur and (kind != cur_kind or weight + w > BATCH):
        flush()
    cur.append(it)
    cur_kind, weight = kind, weight + w
flush()

print("elements:", Counter(e["stereotype"] or e["type"] for e in out_elements))
print("domains:", Counter(e["domain"] for e in out_elements))
print("links:", Counter(l["rel"] for l in links))
print("attributes:", sum(len(e.get("attributes", [])) for e in out_elements),
      " literals:", sum(len(e.get("literals", [])) for e in out_elements))
print(f"process levels derived from structure: {derived}; domain conflicts (child's own domain differs from root): {conflicts}")
print("left out:", Counter(r["reason"] for r in report))
print(f"batches: {n}")
