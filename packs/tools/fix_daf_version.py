"""Align an exported pack TTL with the DAF version it targets.

The M1 exporter writes its own DAF 6.3 contract into the model header
(dafi:dafVersion "6.3", dafi:metamodelExportVersion "1.5.0"), and copies the
EA connector direction into dafi:sourceDirection. EA reverses the direction of
an aggregation when its DAF stereotype is applied, so the pack's aggregations
read "Destination -> Source" although dafm:source and dafm:target already run
the way the metamodel defines. This:

  - sets dafi:dafVersion to the given DAF version and dafi:metamodelExportVersion
    to the generator version of the semantic model;
  - for every relationship that is not semantically reversed and whose
    dafi:sourceDirection is "Destination -> Source" while the metamodel declares
    "Source -> Destination" for its type, writes the metamodel's direction;
  - updates the version lines of the export report and appends what was changed.

dafm:source, dafm:target and the dafpred: projections are not touched. A rerun is
a no-op.

Usage: python3 fix_daf_version.py <pack.ttl> <DAF-semantic-model.ttl> "<DAF version>"
"""

import re
import sys
from pathlib import Path

FORWARD, BACKWARD = "Source -> Destination", "Destination -> Source"
REPORT_MARKER = "POST-PROCESSING (packs/tools/fix_daf_version.py)"


def main():
    pack, model, daf_version = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
    meta = model.read_text(encoding="utf-8-sig")
    generator = re.search(r'dafm:generatorVersion "([^"]+)"', meta).group(1)
    declared = dict(re.findall(r'^dafrel:(\w+) dafm:sourceDirection "([^"]+)" \.', meta, re.M))

    text = pack.read_text(encoding="utf-8-sig")
    text = re.sub(r'(dafi:dafVersion )"[^"]*"', rf'\1"{daf_version}"', text, count=1)
    text = re.sub(r'(dafi:metamodelExportVersion )"[^"]*"', rf'\1"{generator}"', text, count=1)

    fixed = {}

    def align(block):
        rel = re.search(r"dafm:relationshipType dafrel:(\w+) ;", block)
        if not rel or declared.get(rel.group(1)) != FORWARD:
            return block
        if 'dafi:semanticDirectionReversed "false"' not in block or f'dafi:sourceDirection "{BACKWARD}"' not in block:
            return block
        fixed[rel.group(1)] = fixed.get(rel.group(1), 0) + 1
        return block.replace(f'dafi:sourceDirection "{BACKWARD}"', f'dafi:sourceDirection "{FORWARD}"')

    text = "\n\n".join(align(b) if b.lstrip().startswith("# Relationship:") else b for b in text.split("\n\n"))
    pack.write_text(text, encoding="utf-8")

    report = pack.with_suffix(".report.txt")
    if report.exists() and (fixed or REPORT_MARKER not in report.read_text(encoding="utf-8-sig")):
        r = report.read_text(encoding="utf-8-sig").split("\n" + REPORT_MARKER)[0].rstrip("\n")
        r = re.sub(r"^DAF framework version: .*$", f"DAF framework version: {daf_version}", r, count=1, flags=re.M)
        r = re.sub(r"^Semantic metamodel export contract: .*$", f"Semantic metamodel export contract: {generator}", r, count=1, flags=re.M)
        lines = [f"dafi:dafVersion set to {daf_version}; dafi:metamodelExportVersion set to {generator}.",
                 "dafi:sourceDirection aligned with the metamodel (EA had reversed the connector):"]
        lines += [f"  {rel}: {n}" for rel, n in sorted(fixed.items())] or ["  none"]
        report.write_text(r + "\n\n" + REPORT_MARKER + "\n" + "\n".join(lines) + "\n", encoding="utf-8")

    print(f"dafVersion {daf_version}, metamodelExportVersion {generator}; directions aligned: "
          + (", ".join(f"{k} {v}" for k, v in sorted(fixed.items())) or "none"))


if __name__ == "__main__":
    main()
