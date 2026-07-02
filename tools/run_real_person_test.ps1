param(
  [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

$gitPaths = @(
  "C:\Program Files\Git\cmd",
  "C:\Program Files\Git\bin"
)
foreach ($gitPath in $gitPaths) {
  if ((Test-Path (Join-Path $gitPath "git.exe")) -and
      ($env:Path -notlike "*$gitPath*")) {
    $env:Path = "$gitPath;$env:Path"
  }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $projectRoot ".env.local"

if (-not (Test-Path $envPath)) {
  Write-Error "Create .env.local in the project root. Example:
API_BASE_URL=https://avatracker.online/api/v1
TEST_IIN=<12-digit-test-iin>
TEST_BEARER_TOKEN=Bearer <token>
TEST_PHONE=+77000000000"
}

$values = @{}
Get-Content $envPath | ForEach-Object {
  $line = $_.Trim()
  if ($line.Length -eq 0 -or $line.StartsWith("#")) {
    return
  }
  $separator = $line.IndexOf("=")
  if ($separator -le 0) {
    return
  }
  $key = $line.Substring(0, $separator).Trim()
  $value = $line.Substring($separator + 1).Trim()
  if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
      ($value.StartsWith("'") -and $value.EndsWith("'"))) {
    $value = $value.Substring(1, $value.Length - 2)
  }
  $values[$key] = $value
}

$apiBaseUrl = $values["API_BASE_URL"]
if ([string]::IsNullOrWhiteSpace($apiBaseUrl)) {
  $apiBaseUrl = "https://avatracker.online/api/v1"
}

$iin = $values["TEST_IIN"]
$token = $values["TEST_BEARER_TOKEN"]
if ([string]::IsNullOrWhiteSpace($iin)) {
  Write-Error "TEST_IIN is required in .env.local"
}
if ([string]::IsNullOrWhiteSpace($token)) {
  Write-Error "TEST_BEARER_TOKEN is required in .env.local"
}

$flutter = "C:\dev\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
  $flutter = "flutter"
}

$flutterArgs = @(
  "run",
  "--dart-define=API_BASE_URL=$apiBaseUrl",
  "--dart-define=TEST_IIN=$iin",
  "--dart-define=TEST_BEARER_TOKEN=$token"
)

$refreshToken = $values["TEST_REFRESH_TOKEN"]
if (-not [string]::IsNullOrWhiteSpace($refreshToken)) {
  $flutterArgs += "--dart-define=TEST_REFRESH_TOKEN=$refreshToken"
}

$phone = $values["TEST_PHONE"]
if (-not [string]::IsNullOrWhiteSpace($phone)) {
  $flutterArgs += "--dart-define=TEST_PHONE=$phone"
}

$testToday = $values["TEST_TODAY"]
if (-not [string]::IsNullOrWhiteSpace($testToday)) {
  $flutterArgs += "--dart-define=TEST_TODAY=$testToday"
}

if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
  $flutterArgs += @("-d", $DeviceId)
}

& $flutter @flutterArgs
