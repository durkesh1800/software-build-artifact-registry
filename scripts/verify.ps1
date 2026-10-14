param(
    [Parameter(Mandatory = $true)]
    [string]$ArtifactPath,
    [Parameter(Mandatory = $true)]
    [string]$ChecksumsPath
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ArtifactPath -PathType Leaf)) {
    Write-Error "Artifact not found: $ArtifactPath"
    exit 2
}
if (-not (Test-Path -LiteralPath $ChecksumsPath -PathType Leaf)) {
    Write-Error "Checksum manifest not found: $ChecksumsPath"
    exit 2
}

$fileName = [System.IO.Path]::GetFileName($ArtifactPath)
$entry = Get-Content -LiteralPath $ChecksumsPath | Where-Object {
    $parts = $_ -split '\s+', 2
    $parts.Count -eq 2 -and $parts[1].Trim() -eq $fileName
} | Select-Object -First 1
if (-not $entry) {
    Write-Error "No checksum entry found for $fileName"
    exit 2
}
$expected = (($entry -split '\s+', 2)[0]).Trim().ToLowerInvariant()
$actual = (Get-FileHash -LiteralPath $ArtifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Artifact: $fileName"
Write-Host "Expected SHA256: $expected"
Write-Host "Actual SHA256:   $actual"
if ($actual -eq $expected) {
    Write-Host 'PASS: SHA256 checksum matches.' -ForegroundColor Green
    exit 0
}
Write-Host 'FAIL: SHA256 checksum mismatch. Do not deploy this artifact.' -ForegroundColor Red
exit 1
