# Entra ID Access Review Reporter
# Version 4.0 - HTML Dashboard

$ErrorActionPreference = "Stop"

Write-Host "Generating IAM Access Review Dashboard..." -ForegroundColor Cyan

# Project paths
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$InputFile = Join-Path $ProjectRoot "sample-data\sample-users.csv"
$ReportFolder = Join-Path $ProjectRoot "reports"

if (!(Test-Path $InputFile)) {
    throw "Sample user data was not found."
}

if (!(Test-Path $ReportFolder)) {
    New-Item -ItemType Directory -Path $ReportFolder | Out-Null
}

# Import sample data
$Users = @(Import-Csv -Path $InputFile)

# Calculate metrics
$TotalUsers = $Users.Count

$GuestUsers = @($Users | Where-Object {
    $_.UserType -eq "Guest"
})

$DisabledUsers = @($Users | Where-Object {
    $_.AccountEnabled -eq "False"
})

$NoGroupUsers = @($Users | Where-Object {
    [string]::IsNullOrWhiteSpace($_.Groups)
})

# Collect group memberships
$Memberships = @()

foreach ($User in $Users) {

    if (![string]::IsNullOrWhiteSpace($User.Groups)) {

        foreach ($Group in ($User.Groups -split ";")) {

            $Group = $Group.Trim()

            if ($Group -ne "") {

                $Memberships += [PSCustomObject]@{
                    DisplayName = $User.DisplayName
                    GroupName = $Group
                }
            }
        }
    }
}

# Group summary
$GroupSummary = @(
    $Memberships |
        Group-Object GroupName |
        Sort-Object Name
)

# Build findings
$Findings = @()

foreach ($User in $Users) {

    if ($User.AccountEnabled -eq "False") {
        $Findings += [PSCustomObject]@{
            User = $User.DisplayName
            Finding = "Disabled Account"
        }
    }

    if ($User.UserType -eq "Guest") {
        $Findings += [PSCustomObject]@{
            User = $User.DisplayName
            Finding = "Guest Account"
        }
    }

    if ([string]::IsNullOrWhiteSpace($User.Groups)) {
        $Findings += [PSCustomObject]@{
            User = $User.DisplayName
            Finding = "No Group Membership"
        }
    }
}

# HTML encoding helper
function Convert-ToHtmlText {
    param([string]$Value)

    return [System.Net.WebUtility]::HtmlEncode($Value)
}

# Build user table
$UserRows = ""

foreach ($User in $Users) {

    $Name = Convert-ToHtmlText $User.DisplayName
    $UPN = Convert-ToHtmlText $User.UserPrincipalName
    $Type = Convert-ToHtmlText $User.UserType

    $Status = if ($User.AccountEnabled -eq "True") {
        "Enabled"
    }
    else {
        "Disabled"
    }

    $UserRows += @"
<tr>
<td>$Name</td>
<td>$UPN</td>
<td>$Type</td>
<td>$Status</td>
</tr>
"@
}

# Build group table
$GroupRows = ""

foreach ($Group in $GroupSummary) {

    $GroupName = Convert-ToHtmlText $Group.Name

    $GroupRows += @"
<tr>
<td>$GroupName</td>
<td>$($Group.Count)</td>
</tr>
"@
}

# Build findings table
$FindingRows = ""

foreach ($Finding in $Findings) {

    $Name = Convert-ToHtmlText $Finding.User
    $Description = Convert-ToHtmlText $Finding.Finding

    $FindingRows += @"
<tr>
<td>$Name</td>
<td>$Description</td>
</tr>
"@
}

# Timestamp
$Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# HTML dashboard
$HTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>IAM Access Review Dashboard</title>

<style>

body {
    font-family: Arial, sans-serif;
    background: #f3f5f8;
    color: #243247;
    margin: 0;
    padding: 30px;
}

.container {
    max-width: 1100px;
    margin: auto;
}

h1 {
    color: #17365d;
}

.subtitle {
    color: #64748b;
}

.metrics {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 16px;
    margin: 25px 0;
}

.card {
    background: white;
    padding: 22px;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}

.metric {
    font-size: 32px;
    font-weight: bold;
    margin-top: 10px;
    color: #17365d;
}

section {
    background: white;
    padding: 22px;
    margin: 22px 0;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06);
    overflow-x: auto;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 15px;
}

th, td {
    padding: 12px;
    border-bottom: 1px solid #e5e7eb;
    text-align: left;
}

th {
    background: #edf2f7;
}

.footer {
    margin-top: 30px;
    color: #64748b;
    font-size: 13px;
}

</style>
</head>

<body>

<div class="container">

<h1>IAM Access Review Dashboard</h1>

<p class="subtitle">
Identity Governance and Access Review Report
</p>

<p>Generated: $Generated</p>

<div class="metrics">

<div class="card">
Total Accounts
<div class="metric">$TotalUsers</div>
</div>

<div class="card">
Guest Accounts
<div class="metric">$($GuestUsers.Count)</div>
</div>

<div class="card">
Disabled Accounts
<div class="metric">$($DisabledUsers.Count)</div>
</div>

<div class="card">
Accounts Without Listed Groups
<div class="metric">$($NoGroupUsers.Count)</div>
</div>

</div>

<section>

<h2>User Account Inventory</h2>

<table>
<thead>
<tr>
<th>Name</th>
<th>User Principal Name</th>
<th>Account Type</th>
<th>Status</th>
</tr>
</thead>
<tbody>
$UserRows
</tbody>
</table>

</section>

<section>

<h2>Group Membership Summary</h2>

<table>
<thead>
<tr>
<th>Group</th>
<th>Member Count</th>
</tr>
</thead>
<tbody>
$GroupRows
</tbody>
</table>

</section>

<section>

<h2>Access Review Findings</h2>

<table>
<thead>
<tr>
<th>User</th>
<th>Finding</th>
</tr>
</thead>
<tbody>
$FindingRows
</tbody>
</table>

</section>

<div class="footer">

<p>
This dashboard was generated from fictional sample data
for an IAM portfolio project.
</p>

<p>
Findings are indicators for manual review, not proof
of unauthorised access.
</p>

</div>

</div>

</body>
</html>
"@

# Save dashboard
$OutputFile = Join-Path $ReportFolder "IAM_Access_Review_Dashboard.html"

$HTML | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "Dashboard generated successfully!" -ForegroundColor Green
Write-Host "Total accounts: $TotalUsers"
Write-Host "Guest accounts: $($GuestUsers.Count)"
Write-Host "Disabled accounts: $($DisabledUsers.Count)"
Write-Host "Accounts without listed groups: $($NoGroupUsers.Count)"
Write-Host "Total findings: $($Findings.Count)"
Write-Host "Dashboard: $OutputFile"

# Open dashboard in default browser
Invoke-Item $OutputFile