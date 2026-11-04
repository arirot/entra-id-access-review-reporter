# Entra ID Access Review Reporter
# Version 1.0 - Local Test Environment

$ErrorActionPreference = "Stop"

Write-Host "Starting Access Review Reporter..." -ForegroundColor Cyan

# Define project paths
$ProjectRoot = Split-Path $PSScriptRoot -Parent

$InputFile = Join-Path $ProjectRoot "sample-data\sample-users.csv"

$ReportFolder = Join-Path $ProjectRoot "reports"

# Create reports folder if missing
if (!(Test-Path $ReportFolder)) {

    New-Item -ItemType Directory -Path $ReportFolder |
        Out-Null
}

# Import sample users
Write-Host "Loading user data..."

$Users = Import-Csv -Path $InputFile

# Generate timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Generate complete user report
$Users |
    Export-Csv `
    -Path "$ReportFolder\All_Users_$Timestamp.csv" `
    -NoTypeInformation `
    -Encoding UTF8

# Filter guest accounts
$GuestUsers = $Users |
    Where-Object { $_.UserType -eq "Guest" }

# Generate guest report
$GuestUsers |
    Export-Csv `
    -Path "$ReportFolder\Guest_Users_$Timestamp.csv" `
    -NoTypeInformation `
    -Encoding UTF8

# Identify disabled accounts
$DisabledUsers = $Users |
    Where-Object { $_.AccountEnabled -eq "False" }

# Display summary
Write-Host ""
Write-Host "ACCESS REVIEW SUMMARY" -ForegroundColor Green

Write-Host "Total users: $($Users.Count)"
Write-Host "Guest accounts: $($GuestUsers.Count)"
Write-Host "Disabled accounts: $($DisabledUsers.Count)"

Write-Host ""
Write-Host "Reports generated successfully!" -ForegroundColor Green

Write-Host "Report location: $ReportFolder"