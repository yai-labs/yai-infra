import argparse, hashlib, json
from pathlib import Path

REPOS = ["yai", "yai-cli", "yai-law", "yai-specs", "yai-skin", "yai-mind", "yai-yx"]


def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def classify_path(rel: str) -> str:
    # tools/ci/governance rough classification
    if rel.startswith(".github/"):
        return "ci"
    if rel.startswith("tools/") or rel.startswith("scripts/"):
        return "governance"
    if rel.startswith("docs/"):
        # docs triage: runtime vs governance/migration is heuristic
        low = rel.lower()
        if "migration" in low or "cutover" in low or "rollback" in low:
            return "docs-migration"
        if "govern" in low or "policy" in low or "runbook" in low or "delivery" in low:
            return "docs-governance"
        return "docs-runtime"
    return "repo-specific"


def walk_repo(repo_root: Path):
    paths = []
    for p in repo_root.rglob("*"):
        if p.is_dir():
            continue
        # ignore git internals and heavy build dirs
        rel = p.relative_to(repo_root).as_posix()
        if rel.startswith(".git/") or rel.startswith("target/") or rel.startswith("node_modules/"):
            continue
        item = {
            "path": rel,
            "sha256": sha256_file(p),
            "class": classify_path(rel),
            "size": p.stat().st_size,
        }
        paths.append(item)
    return paths


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True, help="directory containing all repos (siblings)")
    ap.add_argument("--out", required=True, help="output directory for .YAI pack")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)

    inventory = {
        "generated_at": __import__("datetime").datetime.now().astimezone().isoformat(),
        "repos": {},
    }

    for name in REPOS:
        repo = root / name
        exists = repo.exists()
        entry = {
            "exists": exists,
            "has_github": (repo / ".github").exists() if exists else False,
            "has_tools": (repo / "tools").exists() if exists else False,
            "has_scripts": (repo / "scripts").exists() if exists else False,
            "has_docs": (repo / "docs").exists() if exists else False,
            "files": walk_repo(repo) if exists else [],
        }
        inventory["repos"][name] = entry

    (out / "yai-infra-inventory.json").write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    # Placeholders for next steps:
    (out / "yai-infra-duplicates.csv").write_text(
        "logical_component,source_repo,source_path,similarity,proposed_owner\n", encoding="utf-8"
    )
    (out / "yai-infra-move-map.yaml").write_text("# TODO: filled after triage\n", encoding="utf-8")
    (out / "yai-infra-cutover-checklist.md").write_text("# Cutover Checklist\n\nTODO\n", encoding="utf-8")


if __name__ == "__main__":
    main()
