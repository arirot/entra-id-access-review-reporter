# Entra ID Access Review Reporter
# Version 3.0 - Group Membership Audit

$ErrorActionPreference = "Stop"

Write-Host "Starting Group Membership Audit..." -ForegroundColor Cyan

# Define project paths
$ProjectRoot = Split-Path $PSScriptRoot -Parent

$InputFile = Join-Path $ProjectRoot "sample-data\sample-users.csv"

$ReportFolder = Join-Path $ProjectRoot "reports"

# Validate input file
if (!(Test-Path $InputFile)) {
    throw "Sample user data was not found."
}

# Create reports directory
if (!(Test-Path $ReportFolder)) {
    New-Item -ItemType Directory -Path $ReportFolder |
        Out-Null
}

# Import sample data
$Users = Import-Csv -Path $InputFile

# Create collections
$MembershipReport = @()
$GroupSummary = @()

# Process users
foreach ($User in $Users) {

    if (![string]::IsNullOrWhiteSpace($User.Groups)) {

        $Groups = $User.Groups -split ";"

        foreach ($Group in $Groups) {

            $Group = $Group.Trim()

            if ($Group -ne "") {

                $MembershipReport += [PSCustomObject]@{

                    DisplayName = $User.DisplayName

                    UserPrincipalName = $User.UserPrincipalName

                    UserType = $User.UserType

                    GroupName = $Group
                }
            }
        }
    }
}

# Generate group summary
$UniqueGroups = $MembershipReport |
    Select-Object -ExpandProperty GroupName -Unique

foreach ($Group in $UniqueGroups) {

    $Members = @(
        $MembershipReport |
        Where-Object { $_.GroupName -eq $Group }
    )

    $GroupSummary += [PSCustomObject]@{

        GroupName = $Group

        MemberCount = $Members.Count

        Members = ($Members.DisplayName -join "; ")
    }
}

# Generate timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Export detailed membership report
$MembershipFile = Join-Path $ReportFolder `
    "Group_Membership_Details_$Timestamp.csv"

$MembershipReport |
    Export-Csv -Path $MembershipFile `
    -NoTypeInformation -Encoding UTF8

# Export group summary
$SummaryFile = Join-Path $ReportFolder `
    "Group_Membership_Summary_$Timestamp.csv"

$GroupSummary |
    Export-Csv -Path $SummaryFile `
    -NoTypeInformation -Encoding UTF8

# Display results
Write-Host "`nGROUP MEMBERSHIP AUDIT" -ForegroundColor Green

Write-Host "Total users reviewed: $($Users.Count)"

Write-Host "Total membership records: $($MembershipReport.Count)"

Write-Host "Unique groups identified: $($UniqueGroups.Count)"

Write-Host "`nGroup membership summary:"

$GroupSummary |
    Format-Table GroupName, MemberCount -AutoSize

Write-Host "Reports generated successfully!" -ForegroundColor Green