# Entra ID Access Review Reporter
# Version 2.0 - Access Review Findings

$ErrorActionPreference = "Stop"

Write-Host "Starting Access Review Findings..." -ForegroundColor Cyan

# Define project paths
$ProjectRoot = Split-Path $PSScriptRoot -Parent

$InputFile = Join-Path $ProjectRoot "sample-data\sample-users.csv"

$ReportFolder = Join-Path $ProjectRoot "reports"

# Check input file
if (!(Test-Path $InputFile)) {
    throw "Sample user data was not found: $InputFile"
}

# Create reports folder if necessary
if (!(Test-Path $ReportFolder)) {
    New-Item -ItemType Directory -Path $ReportFolder |
        Out-Null
}

# Import fictional user data
$Users = Import-Csv -Path $InputFile

# Prepare findings collection
$Findings = @()

foreach ($User in $Users) {

    Write-Host "Reviewing $($User.DisplayName)..."

    $Groups = @()

    if (![string]::IsNullOrWhiteSpace($User.Groups)) {
        $Groups = @($User.Groups -split ";")
    }

    # Check for disabled accounts
    if ($User.AccountEnabled -eq "False") {

        $Findings += [PSCustomObject]@{
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            Finding           = "Disabled Account"
            RiskIndicator     = "Account disabled"
            Recommendation    = "Confirm whether the account should remain disabled."
        }
    }

    # Check for guest accounts
    if ($User.UserType -eq "Guest") {

        $Findings += [PSCustomObject]@{
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            Finding           = "Guest Account"
            RiskIndicator     = "External identity"
            Recommendation    = "Confirm business justification and account ownership."
        }
    }

    # Check for accounts without group memberships
    if ($Groups.Count -eq 0) {

        $Findings += [PSCustomObject]@{
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            Finding           = "No Group Membership"
            RiskIndicator     = "No listed group memberships"
            Recommendation    = "Verify whether the account requires group-based access."
        }
    }
}

# Generate timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Export findings
$OutputFile = Join-Path $ReportFolder `
    "Access_Review_Findings_$Timestamp.csv"

if ($Findings.Count -gt 0) {

    $Findings |
        Export-Csv -Path $OutputFile `
        -NoTypeInformation -Encoding UTF8

    Write-Host "`nAccess review findings generated." -ForegroundColor Green

    Write-Host "Total accounts reviewed: $($Users.Count)"
    Write-Host "Total findings: $($Findings.Count)"

    Write-Host "Disabled accounts: $(($Findings | Where-Object Finding -eq 'Disabled Account').Count)"
    Write-Host "Guest accounts: $(($Findings | Where-Object Finding -eq 'Guest Account').Count)"
    Write-Host "No group membership: $(($Findings | Where-Object Finding -eq 'No Group Membership').Count)"

    Write-Host "Report: $OutputFile"
}
else {
    Write-Host "No review findings identified."
}