#!/usr/bin/env python3
"""Check the Aphrodites 3.0 example files.

Run from this folder:  python3 check_examples.py
Needs the Python package `jsonschema`. Exit code 0 means every example behaved as expected.

It checks three things and no more:
- every example against its schema;
- on a change package, the digest named in the approval and the example proof;
- that a package or a report names a manifest that is among the valid examples.
"""
import hashlib
import hmac
import json
import pathlib
import sys

import jsonschema

HERE = pathlib.Path(__file__).parent
EXAMPLE_PROOF_KIND = "example-hmac-sha256"
# A public test value, used only by the examples. It is not a secret.
EXAMPLE_PROOF_KEY = b"aphrodites-example-key"

# The first check each invalid example must fail.
EXPECTED_FAILURE = {
    "package-missing-approval.json": "schema",
    "package-altered-after-approval.json": "digest",
    "package-altered-approver.json": "proof",
    "evidence-with-model-identifier.json": "schema",
}

# The values the README gives as known answers.
KNOWN_ANSWERS = {
    "manifest digest": "sha256:5ce2d8d72ce65c20ab735805c80047f2fc566171790149ff06c75ae31e78d979",
    "package digest": "sha256:9679ccf7db35d35b4a4dd47351731d203da8d6e495cf7b9e2aac9310dcdcc884",
    "approval digest": "sha256:08c7460e53f5f5918d2ba188b78917260cfc4a94418c0a50784ebb84f61132ca",
    "proof": "dc46dcd2d079ec88b0a83e5797b7621cc8a758e40c803566d652852e33579f09",
}


def canonical(value):
    """The fixed form a document is written in before it is digested: RFC 8785.

    shortcut: correct for text, whole numbers, true, false, lists and objects with
    plain names, which is all the examples use. Use a full RFC 8785 library before
    digesting numbers with a fraction.
    """
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def digest(value):
    return "sha256:" + hashlib.sha256(canonical(value)).hexdigest()


def package_digest(package):
    """Rule 5.2: the digest covers the package without its approval and proof."""
    return digest({k: v for k, v in package.items() if k not in ("approval", "proof")})


def example_proof(approval):
    """HMAC-SHA256 over the approval digest as text: "sha256:" and 64 hex digits, no line end."""
    return hmac.new(EXAMPLE_PROOF_KEY, digest(approval).encode("ascii"), hashlib.sha256).hexdigest()


def kind_of(document):
    if document.get("schema") == "aphrodites/manifest/v1":
        return "manifest"
    if document.get("schema") == "aphrodites/change-package/v1":
        return "change-package"
    return "evidence"


def first_failure(document, schemas, manifests):
    """The name of the first check the document fails, or None."""
    kind = kind_of(document)
    if list(jsonschema.Draft202012Validator(schemas[kind]).iter_errors(document)):
        return "schema"
    if kind == "change-package":
        if document["approval"]["package_digest"] != package_digest(document):
            return "digest"
        # A proof this script cannot verify counts as a failure (rule 5.3).
        if document["proof"]["kind"] != EXAMPLE_PROOF_KIND or not hmac.compare_digest(
                document["proof"]["value"], example_proof(document["approval"])):
            return "proof"
    named = document.get("binding") if kind == "change-package" else document.get("data", {}).get("binding")
    if kind != "manifest" and named not in manifests:
        return "manifest"
    return None


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    schemas = {name: read(HERE / f"{name}.schema.json") for name in ("manifest", "change-package", "evidence")}
    for schema in schemas.values():
        jsonschema.Draft202012Validator.check_schema(schema)
    valid = sorted((HERE / "examples" / "valid").glob("*.json"))
    invalid = sorted((HERE / "examples" / "invalid").glob("*.json"))
    manifests = {digest(doc) for doc in map(read, valid) if kind_of(doc) == "manifest"}

    ok = True

    def line(good, text):
        nonlocal ok
        ok &= good
        print(("ok   " if good else "FAIL ") + text)

    for path in valid:
        failure = first_failure(read(path), schemas, manifests)
        line(failure is None, f"valid/{path.name}: {'passes' if failure is None else 'fails ' + failure}")
    for path in invalid:
        failure = first_failure(read(path), schemas, manifests)
        line(failure == EXPECTED_FAILURE.get(path.name),
             f"invalid/{path.name}: expected to fail {EXPECTED_FAILURE.get(path.name)}, fails {failure}")
    line(set(EXPECTED_FAILURE) == {p.name for p in invalid}, "every listed invalid example is present")
    package = read(HERE / "examples" / "valid" / "package-l1-setting.json")
    answers = {
        "manifest digest": digest(read(HERE / "examples" / "valid" / "manifest-customer-inquiry.json")),
        "package digest": package_digest(package),
        "approval digest": digest(package["approval"]),
        "proof": example_proof(package["approval"]),
    }
    for name, value in answers.items():
        line(value == KNOWN_ANSWERS[name], f"known answer, {name}: {value}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
