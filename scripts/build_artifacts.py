from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
VERSIONS = ("v1.0.0", "v2.0.0")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    DIST.mkdir(exist_ok=True)
    build_id = os.environ.get("GITHUB_RUN_ID", "local")
    commit = os.environ.get("GITHUB_SHA", "working-tree")
    artifacts = []

    for version in VERSIONS:
        source = ROOT / "versions" / version
        output = DIST / f"app-{version}.zip"
        with ZipFile(output, "w", ZIP_DEFLATED) as archive:
            for file in sorted(p for p in source.rglob("*") if p.is_file()):
                archive.write(file, arcname=file.relative_to(source).as_posix())
        artifacts.append({
            "version": version,
            "filename": output.name,
            "sha256": sha256(output),
            "size_bytes": output.stat().st_size,
        })

    metadata = {
        "project": "software-build-artifact-registry",
        "build_id": build_id,
        "commit": commit,
        "artifacts": artifacts,
    }
    (DIST / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    (DIST / "SHA256SUMS.txt").write_text(
        "".join(f"{item['sha256']}  {item['filename']}\n" for item in artifacts),
        encoding="utf-8",
    )
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
