"""Generate Metamodel_json/DAFSchema.json and API/DigitalArchitectureFramework-OAS.yaml from the DAF semantic model.

The semantic model (technology/rdf/DAF-semantic-model.ttl) is the authoritative M2 definition; its SHACL shapes give
every property's type and multiplicity. Names are the metamodel's: properties keep their labels, relationships are
keyed by their predicate (forward) and predicate + "_inverse" (backward).

The curated parts of the existing OAS are kept: info (version updated), DAFBase with its read-only policy, and the
"id" parameter. Everything else is regenerated.

usage: gen_schema_oas.py <ttl> <existing-oas> <out-json-schema> <out-oas> <version>
"""
import json
import sys
from collections import OrderedDict

import yaml
from rdflib import Graph, Namespace, RDF, RDFS, URIRef, BNode
from rdflib.collection import Collection

TTL, OLD_OAS, OUT_SCHEMA, OUT_OAS, VERSION = sys.argv[1:6]

DAF = Namespace("https://freetakteam.github.io/DAF/model#")
DAFM = Namespace("https://freetakteam.github.io/DAF/metamodel#")
DAFP = Namespace("https://freetakteam.github.io/DAF/property#")
DAFPRED = Namespace("https://freetakteam.github.io/DAF/predicate#")
DAFREL = Namespace("https://freetakteam.github.io/DAF/relationship#")
DAFENUM = Namespace("https://freetakteam.github.io/DAF/enum#")
SH = Namespace("http://www.w3.org/ns/shacl#")
SKOS = Namespace("http://www.w3.org/2004/02/skos/core#")
XSD = "http://www.w3.org/2001/XMLSchema#"

# value types are embedded in their owner; every other class is referenced by id
VALUE_TYPES = {"dQuantityValue"}
JSON_TYPES = {
    "string": {"type": "string"},
    "boolean": {"type": "boolean"},
    "date": {"type": "string", "format": "date"},
    "dateTime": {"type": "string", "format": "date-time"},
    "duration": {"type": "string", "format": "duration"},
    "decimal": {"type": "number"},
    "float": {"type": "number"},
    "double": {"type": "number"},
    "int": {"type": "integer"},
    "integer": {"type": "integer"},
    "long": {"type": "integer", "format": "int64"},
}

g = Graph()
g.parse(TTL, format="turtle")


def local(iri):
    s = str(iri)
    return s.rsplit("#", 1)[-1]


def text(node, pred):
    v = g.value(node, pred)
    return str(v).strip() if v is not None else ""


# ---------------------------------------------------------------- concepts and their shapes
shapes = {}
for shape, cls in g.subject_objects(SH.targetClass):
    if str(cls).startswith(str(DAF)):  # relationship types have shapes too
        shapes[local(cls)] = shape
concepts = sorted(c for c in shapes if c != "DAFBase")
concept_notes = {c: text(DAF[c], RDFS.comment) for c in concepts}
parents = {}
for c in concepts:
    for p in g.objects(DAF[c], RDFS.subClassOf):
        if str(p).startswith(str(DAF)) and local(p) not in ("DAFBase",):
            parents[c] = local(p)

# enumerations: scheme -> ordered members
enums = OrderedDict()
for scheme in sorted(g.subjects(RDF.type, DAFM.Enumeration), key=local):
    members = sorted(g.subjects(SKOS.inScheme, scheme), key=lambda m: str(g.value(m, SKOS.prefLabel)))
    enums[local(scheme)] = {
        "description": text(scheme, RDFS.comment),
        "values": [str(g.value(m, SKOS.prefLabel)) for m in members],
    }

# relationship types
relationships = []
for rel in sorted(g.subjects(RDF.type, DAFM.RelationshipType), key=local):
    relationships.append({
        "name": local(rel),
        "guid": text(rel, DAFM.eaGuid).strip("{}"),
        "alias": text(rel, RDFS.label),
        "kind": text(rel, DAFM.relationshipKind),
        "source": local(g.value(rel, DAFM.sourceClass)),
        "target": local(g.value(rel, DAFM.targetClass)),
        "sourceMultiplicity": text(rel, DAFM.sourceMultiplicity),
        "targetMultiplicity": text(rel, DAFM.targetMultiplicity),
        "forwardRole": text(rel, DAFM.forwardRole),
        "backwardRole": text(rel, DAFM.backwardRole),
        "description": text(rel, RDFS.comment),
    })
rel_by_pred = {}
for r in relationships:
    rel_by_pred[r["name"]] = r


def shape_properties(cls):
    """Yield (key, spec) for every property of the shape, in a stable order: attributes first, then relationships."""
    attrs, rels = [], []
    for bn in g.objects(shapes[cls], SH.property):
        path = g.value(bn, SH.path)
        inverse = False
        if isinstance(path, BNode):
            path = g.value(path, SH.inversePath)
            inverse = True
        spec = {
            "min": int(g.value(bn, SH.minCount) or 0),
            "max": int(g.value(bn, SH.maxCount)) if g.value(bn, SH.maxCount) is not None else None,
            "datatype": local(g.value(bn, SH.datatype)) if g.value(bn, SH.datatype) is not None else None,
            "class": local(g.value(bn, SH["class"])) if g.value(bn, SH["class"]) is not None else None,
            "in": [str(x) for x in Collection(g, g.value(bn, SH["in"]))] if g.value(bn, SH["in"]) is not None else None,
        }
        if str(path).startswith(str(DAFP)):
            spec["name"] = text(bn, SH.name) or text(path, RDFS.label)
            spec["description"] = text(path, RDFS.comment)
            spec["range"] = g.value(path, RDFS.range)
            attrs.append((spec["name"], spec))
        elif str(path).startswith(str(DAFPRED)):
            pred = local(path)
            rel = rel_by_pred.get(pred)
            if rel is None:
                continue
            key = pred + ("_inverse" if inverse else "")
            role = rel["backwardRole"] if inverse else rel["forwardRole"]
            other = rel["source"] if inverse else rel["target"]
            mult = rel["sourceMultiplicity"] if inverse else rel["targetMultiplicity"]
            spec["description"] = f"{role} ({rel['alias']}). Ids of the {other} elements; multiplicity {mult}." + (f" {rel['description']}" if rel["description"] and not inverse else "")
            spec["class"] = other
            spec["relationship"] = True
            rels.append((key, spec))
    attrs.sort(key=lambda kv: kv[0].lower())
    rels.sort(key=lambda kv: kv[0].lower())
    return attrs + rels


def enum_of(spec):
    rng = spec.get("range")
    if rng is not None and str(rng).startswith(str(DAFENUM)):
        return local(rng)
    if spec.get("in"):
        for name, e in enums.items():
            if sorted(e["values"]) == sorted(spec["in"]):
                return name
    return None


def json_type(spec, ref_prefix, reference):
    """The JSON Schema / OAS type of one value of a property."""
    if spec.get("relationship") or (spec.get("class") and spec["class"] not in VALUE_TYPES):
        return reference(spec["class"])
    if spec.get("class"):
        return {"$ref": ref_prefix + spec["class"]}
    e = enum_of(spec)
    if e:
        return {"$ref": ref_prefix + e}
    if spec.get("in"):
        return {"type": "string", "enum": spec["in"]}
    return dict(JSON_TYPES.get(spec.get("datatype") or "string", {"type": "string"}))


def wrap(spec, item):
    many = spec["max"] is None or spec["max"] > 1
    out = {"type": "array", "items": item} if many else dict(item)
    if spec.get("description"):
        out["description"] = spec["description"]
    return out


# ---------------------------------------------------------------- JSON Schema (draft 2020-12)
def schema_ref(cls):
    return {"type": "string", "format": "uuid", "x-reference": "#/$defs/" + cls}


defs = OrderedDict()
base_props, base_required = OrderedDict(), []
for key, spec in shape_properties("DAFBase"):
    base_props[key] = wrap(spec, json_type(spec, "#/$defs/", schema_ref))
    if spec["min"] >= 1:
        base_required.append(key)
defs["DAFBase"] = {"description": text(DAF.DAFBase, RDFS.comment), "type": "object", "properties": base_props}
if base_required:
    defs["DAFBase"]["required"] = base_required
for name, e in enums.items():
    defs[name] = {"description": e["description"], "type": "string", "enum": e["values"]}
for c in concepts:
    props, required = OrderedDict(), []
    for key, spec in shape_properties(c):
        props[key] = wrap(spec, json_type(spec, "#/$defs/", schema_ref))
        if spec["min"] >= 1:
            required.append(key)
    own = {"type": "object", "properties": props}
    if required:
        own["required"] = required
    base = "#/$defs/" + parents.get(c, "DAFBase")
    defs[c] = {"description": concept_notes[c], "allOf": [{"$ref": base}, own]}
    if c in VALUE_TYPES:
        defs[c] = dict(own, description=concept_notes[c])
schema = OrderedDict([
    ("$schema", "https://json-schema.org/draft/2020-12/schema"),
    ("$id", "https://freetakteam.github.io/DAF/schema/DigitalArchitectureFramework.schema.json"),
    ("title", "DigitalArchitectureFramework"),
    ("description", f"JSON Schema of the DAF {VERSION} metamodel, generated from technology/rdf/DAF-semantic-model.ttl. Relationships hold the ids of the related elements (x-reference names the target)."),
    ("x-daf-version", VERSION),
    ("type", "object"),
    ("properties", OrderedDict((c, {"type": "array", "items": {"$ref": "#/$defs/" + c}}) for c in concepts if c not in VALUE_TYPES)),
    ("$defs", defs),
])
with open(OUT_SCHEMA, "w", encoding="utf-8", newline="\n") as f:
    json.dump(schema, f, indent=4, ensure_ascii=False)
    f.write("\n")

# ---------------------------------------------------------------- OpenAPI 3.0
old = yaml.safe_load(open(OLD_OAS, encoding="utf-8"))
info = old["info"]
info["version"] = VERSION


def oas_ref(cls):
    return {"type": "string", "format": "uuid", "x-reference": "#/components/schemas/" + cls}


def oas_fix(node):
    """OpenAPI 3.0 has no $ref siblings: wrap a described $ref in allOf."""
    if isinstance(node, dict):
        if "$ref" in node and len(node) > 1:
            extra = {k: v for k, v in node.items() if k != "$ref"}
            return dict(allOf=[{"$ref": node["$ref"]}], **extra)
        return {k: oas_fix(v) for k, v in node.items()}
    if isinstance(node, list):
        return [oas_fix(v) for v in node]
    return node


schemas = OrderedDict()
schemas["DAFBase"] = old["components"]["schemas"]["DAFBase"]
for name, e in enums.items():
    schemas[name] = {"description": e["description"], "type": "string", "enum": e["values"]}
for c in concepts:
    props, required = OrderedDict(), []
    for key, spec in shape_properties(c):
        item = json_type(spec, "#/components/schemas/", oas_ref)
        p = wrap(spec, item)
        if spec["min"] == 0 and not (spec["max"] is None or spec["max"] > 1):
            p["nullable"] = True
        props[key] = oas_fix(p)
        if spec["min"] >= 1:
            required.append(key)
    own = {"type": "object", "properties": props}
    if required:
        own["required"] = required
    if c in VALUE_TYPES:
        schemas[c] = dict(own, description=concept_notes[c])
    else:
        schemas[c] = {"description": concept_notes[c], "allOf": [{"$ref": "#/components/schemas/" + parents.get(c, "DAFBase")}, own]}

paths, responses, bodies = OrderedDict(), OrderedDict(), OrderedDict()
for c in concepts:
    if c in VALUE_TYPES:
        continue
    ref = {"$ref": "#/components/schemas/" + c}
    for op in ("post", "delete", "get", "patch"):
        responses[f"200{c}_{op}"] = {"description": "Success", "content": {"application/json": {"schema": ({"type": "array", "items": ref} if op == "get" else ref)}}}
    responses[f"200{c}_get_one"] = {"description": "Success", "content": {"application/json": {"schema": ref}}}
    bodies[c] = {"description": concept_notes[c], "content": {"application/json": {"schema": ref}}, "required": True}
    common = {"x-scope": "public", "tags": [c]}
    paths[f"/{c}"] = OrderedDict([
        ("post", dict(common, summary=f"Creates a new {c} record.", operationId=f"Create{c}", requestBody={"$ref": f"#/components/requestBodies/{c}"}, responses={"200": {"$ref": f"#/components/responses/200{c}_post"}})),
        ("get", dict(common, summary=f"Retrieves a list of all {c} records.", operationId=f"List{c}", responses={"200": {"$ref": f"#/components/responses/200{c}_get"}})),
    ])
    paths[f"/{c}/{{id}}"] = OrderedDict([
        ("get", dict(common, summary=f"Retrieves an existing {c} record by its id.", operationId=f"Retrieve{c}", parameters=[{"$ref": "#/components/parameters/id"}], responses={"200": {"$ref": f"#/components/responses/200{c}_get_one"}})),
        ("patch", dict(common, summary=f"Updates an existing {c} record.", operationId=f"Patch{c}", parameters=[{"$ref": "#/components/parameters/id"}], requestBody={"$ref": f"#/components/requestBodies/{c}"}, responses={"200": {"$ref": f"#/components/responses/200{c}_patch"}})),
        ("delete", dict(common, summary=f"Deletes an existing {c} record by its id.", operationId=f"Delete{c}", parameters=[{"$ref": "#/components/parameters/id"}], responses={"200": {"$ref": f"#/components/responses/200{c}_delete"}})),
    ])

uml = []
for r in relationships:
    uml.append(OrderedDict([
        ("name", r["name"]), ("x-ea-guid", r["guid"]), ("alias", r["alias"]), ("kind", r["kind"]),
        ("source", OrderedDict([("schema", "#/components/schemas/" + r["source"]), ("multiplicity", r["sourceMultiplicity"]), ("role", r["backwardRole"])])),
        ("target", OrderedDict([("schema", "#/components/schemas/" + r["target"]), ("multiplicity", r["targetMultiplicity"]), ("role", r["forwardRole"])])),
    ]))

oas = OrderedDict([
    ("openapi", "3.0.1"),
    ("info", info),
    ("paths", paths),
    ("components", OrderedDict([("schemas", schemas), ("parameters", old["components"]["parameters"]), ("responses", responses), ("requestBodies", bodies)])),
    ("x-uml-relationships", uml),
])


class Dumper(yaml.SafeDumper):
    pass


Dumper.add_representer(OrderedDict, lambda d, data: d.represent_mapping("tag:yaml.org,2002:map", data.items()))
Dumper.ignore_aliases = lambda self, data: True
with open(OUT_OAS, "w", encoding="utf-8", newline="\n") as f:
    yaml.dump(oas, f, Dumper=Dumper, sort_keys=False, allow_unicode=True, width=200)

print(f"concepts {len(concepts)}, enumerations {len(enums)}, relationships {len(relationships)}, paths {len(paths)}")
