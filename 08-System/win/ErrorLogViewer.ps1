# ErrorLogViewer.ps1
# A quick tool to view Windows system error logs
param (
    [Parameter(Mandatory=$false)]
    [string]$LogName = "System",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxEvents = 50,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Error", "Warning", "Information", "All")]
    [string]$Level = "Error",
    
    [Parameter(Mandatory=$false)]
    [int]$HoursBack = 24,
    
    [Parameter(Mandatory=$false)]
    [string]$ExportPath
)

# Define colors for different levels
$ErrorColor = "Red"
$WarningColor = "Yellow"
$InfoColor = "Green"
$DefaultColor = "White"

# Get the current date and calculate the time window
$endTime = Get-Date
$startTime = $endTime.AddHours(-$HoursBack)

Write-Host "Retrieving $Level events from $LogName log for the past $HoursBack hours..." -ForegroundColor Cyan

# Prepare the filter based on level
$filterXml = $null
if ($Level -ne "All") {
    # Create a filter for specific level
    # Error = 2, Warning = 3, Information = 4
    switch($Level) {
        "Error" { $levelValue = 2 }
        "Warning" { $levelValue = 3 }
        "Information" { $levelValue = 4 }
    }
    
    $filterXml = @"
<QueryList>
  <Query Id="0" Path="$LogName">
    <Select Path="$LogName">*[System[(Level=$levelValue) and TimeCreated[@SystemTime&gt;='$($startTime.ToUniversalTime().ToString("o"))' and @SystemTime&lt;='$($endTime.ToUniversalTime().ToString("o"))']]]</Select>
  </Query>
</QueryList>
"@
    $events = Get-WinEvent -FilterXml $filterXml -MaxEvents $MaxEvents -ErrorAction SilentlyContinue
}
else {
    # Get all levels of events
    $filterXml = @"
<QueryList>
  <Query Id="0" Path="$LogName">
    <Select Path="$LogName">*[System[TimeCreated[@SystemTime&gt;='$($startTime.ToUniversalTime().ToString("o"))' and @SystemTime&lt;='$($endTime.ToUniversalTime().ToString("o"))']]]</Select>
  </Query>
</QueryList>
"@
    $events = Get-WinEvent -FilterXml $filterXml -MaxEvents $MaxEvents -ErrorAction SilentlyContinue
}

# Handle when no events are found
if ($null -eq $events -or $events.Count -eq 0) {
    Write-Host "No $Level events found in the $LogName log for the past $HoursBack hours." -ForegroundColor Yellow
    exit
}

Write-Host "Found $($events.Count) $Level event(s)" -ForegroundColor Cyan
Write-Host "---------------------------------------" -ForegroundColor Cyan

# Display events
foreach ($event in $events) {
    # Set color based on level
    switch ($event.Level) {
        2 { $color = $ErrorColor }
        3 { $color = $WarningColor }
        4 { $color = $InfoColor }
        default { $color = $DefaultColor }
    }
    
    Write-Host "Time:    " -NoNewline
    Write-Host $event.TimeCreated -ForegroundColor $color
    Write-Host "Level:   " -NoNewline
    Write-Host $(
        switch ($event.Level) {
            2 { "Error" }
            3 { "Warning" }
            4 { "Information" }
            default { "Level $($event.Level)" }
        }
    ) -ForegroundColor $color
    Write-Host "Source:  " -NoNewline
    Write-Host $event.ProviderName -ForegroundColor $color
    Write-Host "EventID: " -NoNewline
    Write-Host $event.Id -ForegroundColor $color
    Write-Host "Message: " -NoNewline
    Write-Host $event.Message -ForegroundColor $color
    Write-Host "---------------------------------------" -ForegroundColor Cyan
}

# Export if requested
if ($ExportPath) {
    $events | Select-Object TimeCreated, Level, ProviderName, Id, Message |
    Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Events exported to $ExportPath" -ForegroundColor Green
}
