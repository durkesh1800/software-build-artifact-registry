# Software Build Artifact Registry

A lightweight DevOps hackathon demo that builds two distinguishable, versioned ZIP artifacts, publishes them as GitHub Release assets, records SHA-256 checksums and build metadata, and verifies a retrieved artifact before deployment.

## Deliverables

- `app-v1.0.0.zip` and `app-v2.0.0.zip`
- `SHA256SUMS.txt` containing the SHA-256 digest for each ZIP
- `metadata.json` containing version, build ID, commit, size, and checksum
- GitHub Actions workflow at `.github/workflows/publish-artifacts.yml`
- PowerShell verification and retrieval scripts under `scripts/`

## 1. Create and push the repository

Create a new GitHub repository named `software-build-artifact-registry`. In PowerShell, from this folder run:

```powershell
git init
git branch -M main
git add .
git commit -m "Build versioned artifacts with SHA256 verification"
git remote add origin https://github.com/OWNER/REPO.git
git push -u origin main
```

Replace `OWNER/REPO` with your actual GitHub username and repository name. If Git asks you to authenticate, follow the browser prompt.

## 2. Publish both artifacts

The workflow runs when relevant files are pushed to `main`, or can be started manually:

1. Open the repository on GitHub.
2. Select **Actions** → **Build and publish versioned artifacts**.
3. Select **Run workflow** → **Run workflow**.
4. Wait for the job to finish successfully.
5. Open **Releases** and select **Software Build Artifact Registry Demo**.

The workflow needs `contents: write` permission to create/update its prerelease and upload assets. If organization policies block this permission, use a repository where Actions can write releases.

## 3. Retrieve and verify one version on Windows

Install GitHub CLI from <https://cli.github.com/>. Then in PowerShell:

```powershell
gh auth login
# From the project root; replace OWNER/REPO:
.\scripts\retrieve-and-verify.ps1 -Version v1.0.0 -Repository OWNER/REPO
```

To retrieve the second version instead, use `-Version v2.0.0`. The script downloads the selected ZIP and `SHA256SUMS.txt`, calculates the downloaded file's SHA-256 hash, and exits with a nonzero code if the digest does not match.

You can also download assets through the GitHub Releases page and run the verifier directly:

```powershell
.\scripts\verify.ps1 -ArtifactPath .\retrieved\app-v1.0.0.zip -ChecksumsPath .\retrieved\SHA256SUMS.txt
```

## 4. Local build and test (no Docker required)

Python 3.10+ is sufficient for the build script; it uses only the standard library.

```powershell
py .\scripts\build_artifacts.py
Get-Content .\dist\SHA256SUMS.txt
Get-Content .\dist\metadata.json
.\scripts\verify.ps1 -ArtifactPath .\dist\app-v1.0.0.zip -ChecksumsPath .\dist\SHA256SUMS.txt
```

Expected result: `PASS: SHA256 checksum matches.`

## 5. Demonstrate tamper detection

This intentionally corrupts a copy of the artifact; keep the original untouched:

```powershell
Copy-Item .\dist\app-v1.0.0.zip .\dist\app-v1.0.0-tampered.zip
Add-Content .\dist\app-v1.0.0-tampered.zip 'tampered'
.\scripts\verify.ps1 -ArtifactPath .\dist\app-v1.0.0-tampered.zip -ChecksumsPath .\dist\SHA256SUMS.txt
```

The tampered file name is not in the manifest, so the verifier should reject it. To demonstrate a direct hash mismatch for the same name, copy it into a separate folder named `app-v1.0.0.zip` and verify it against the original `SHA256SUMS.txt`; expected result is `FAIL: SHA256 checksum mismatch.`

## Demo checklist

- [ ] GitHub Actions run succeeded.
- [ ] Release contains both versioned ZIP files.
- [ ] `metadata.json` shows the build ID, commit and both SHA-256 digests.
- [ ] Retrieve `v1.0.0` and show a successful checksum verification.
- [ ] Demonstrate rejection of a modified artifact.
- [ ] Explain: build → version → publish → retrieve → verify → deploy only on PASS.

## Integrity note

SHA-256 detects accidental or unauthorized changes only when the expected checksum itself is trusted. For stronger production provenance, protect release permissions and consider signed checksums/attestations. This demo's release tag is intentionally fixed for easy hackathon reruns; production systems should use immutable, unique release tags.
## Live Deployment

**ArtifactHub Website:** https://black-violet-2fba.udhayadk10.workers.dev

Hosted on Cloudflare Workers.

* [Source Repository](https://github.com/durkesh1800/software-build-artifact-registry)
* [GitHub Releases](https://github.com/durkesh1800/software-build-artifact-registry/releases)
* [GitHub Actions](https://github.com/durkesh1800/software-build-artifact-registry/actions)

**Status:** The live website is deployed. Browser-based checksum verification still requires end-to-end testing.
