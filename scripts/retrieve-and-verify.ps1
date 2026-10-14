param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('v1.0.0', 'v2.0.0')]
    [string]$Version,
    [Parameter(Mandatory = $true)]
    [string]$Repository # format: OWNER/REPO
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required. Install it from https://cli.github.com/ and reopen PowerShell.'
}
$null = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    throw 'Sign in first with: gh auth login'
}
$downloadDir = Join-Path (Get-Location) 'retrieved'
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
$artifactName = "app-$Version.zip"

gh release download artifact-registry-demo --repo $Repository --pattern $artifactName --pattern SHA256SUMS.txt --dir $downloadDir --clobber
if ($LASTEXITCODE -ne 0) { throw 'Artifact download failed. Check the repository, release, and authentication.' }

& (Join-Path $PSScriptRoot 'verify.ps1') -ArtifactPath (Join-Path $downloadDir $artifactName) -ChecksumsPath (Join-Path $downloadDir 'SHA256SUMS.txt')
if ($LASTEXITCODE -ne 0) { throw 'Verification failed. Do not deploy the artifact.' }
Write-Host "Verified artifact saved to: $downloadDir\$artifactName"
