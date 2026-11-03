"""Copy check for rephrased pack content, and merge of the results that pass (MAPPING.md, Rewriting).

usage: check_results.py <local dir>
For every batches/b_NNN.json with a results/r_NNN.json, checks each item (and its attributes and
literals) and adds what passes to rephrased.json. Items that fail, or have no result, are written
to batches/retry_NNN.json for one more round; a second failure is reported in check_failures.json.
"""
import json
import re
import sys
from pathlib import Path

FORBIDDEN = re.compile(r"\b(tm ?forum|tmf|sid|etom|tam|abe|aggregated functions?)\b", re.I)
NGRAM = 6


def words(text):
    text = re.sub(r"([a-z])([A-Z])", r"\1 \2", text or "")
    return re.findall(r"[a-z0-9]+", text.lower())


def grams(tokens):
    return {tuple(tokens[i:i + NGRAM]) for i in range(len(tokens) - NGRAM + 1)}


def problems(src_name, src_text, name, definition, need_definition=True):
    out = []
    if not (name or "").strip() or (need_definition and not (definition or "").strip()):
        out.append("empty")
    sn = words(src_name)
    if len(sn) >= 3 and words(name) == sn:
        out.append("name equals source")
    if need_definition and grams(words(definition)) & grams(words(src_text)):
        out.append("definition copies source")
    if FORBIDDEN.search(f"{name} {definition or ''}"):
        out.append("names the source standard")
    return out


def check_item(src, res):
    issues = problems(src["source_name"], src["source_text"], res.get("name"), res.get("definition"))
    got = {a.get("key"): a for a in res.get("attributes") or []}
    for a in src.get("attributes", []):
        r = got.get(a["key"])
        if r is None:
            issues.append(f"attribute {a['source_name']}: missing")
        else:
            issues += [f"attribute {a['source_name']}: {p}" for p in
                       problems(a["source_name"], a["source_text"], r.get("name"), r.get("definition"))]
    lits = {l.get("key"): l for l in res.get("literals") or []}
    for l in src.get("literals", []):
        r = lits.get(l["key"])
        if r is None:
            issues.append(f"literal {l['source_name']}: missing")
        else:
            issues += [f"literal {l['source_name']}: {p}" for p in problems(l["source_name"], "", r.get("name"), None, False)]
    return issues


def main():
    folder = Path(sys.argv[1])
    done_path, fail_path = folder / "rephrased.json", folder / "check_failures.json"
    done = json.loads(done_path.read_text(encoding="utf-8")) if done_path.exists() else {}
    final_failures = json.loads(fail_path.read_text(encoding="utf-8")) if fail_path.exists() else {}
    passed = failed = 0
    for bfile in sorted((folder / "batches").glob("*.json")):
        rfile = folder / "results" / bfile.name.replace("b_", "r_").replace("retry_", "rr_")
        if not rfile.exists():
            continue
        is_retry = bfile.name.startswith("retry_")
        sources = json.loads(bfile.read_text(encoding="utf-8"))
        try:
            results = {r.get("key"): r for r in json.loads(rfile.read_text(encoding="utf-8"))}
        except json.JSONDecodeError as e:
            results = {}
            print(f"{rfile.name}: invalid JSON ({e})")
        retry = []
        for src in sources:
            if src["key"] in done:
                continue
            res = results.get(src["key"])
            issues = ["no result"] if res is None else check_item(src, res)
            if not issues:
                entry = {"name": res["name"].strip(), "definition": res["definition"].strip()}
                if src.get("attributes"):
                    entry["attributes"] = {a["key"]: {"name": a["name"].strip(), "definition": a["definition"].strip()}
                                           for a in res["attributes"]}
                if src.get("literals"):
                    entry["literals"] = {l["key"]: l["name"].strip() for l in res["literals"]}
                done[src["key"]] = entry
                passed += 1
            else:
                failed += 1
                if is_retry:
                    final_failures[src["key"]] = {"source_name": src["source_name"], "issues": issues}
                else:
                    retry.append(src)
        if retry:
            (folder / "batches" / bfile.name.replace("b_", "retry_")).write_text(
                json.dumps(retry, ensure_ascii=False, indent=1), encoding="utf-8")
    done_path.write_text(json.dumps(done, ensure_ascii=False, indent=1), encoding="utf-8")
    fail_path.write_text(json.dumps(final_failures, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"passed {passed}, failed {failed}; total rephrased {len(done)}, final failures {len(final_failures)}")


if __name__ == "__main__":
    main()
