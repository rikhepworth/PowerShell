# Function that will execute the test and call AppInsights
function Send-AvailabilityResult {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,
        [Parameter(Mandatory = $true)]
        [string]
        $TestUrl,
        [Parameter(Mandatory = $true)]
        [string]
        $UrlPath,
        [Parameter(Mandatory = $true)]
        [string]
        $Method,
        [Parameter(Mandatory = $true)]
        [string]
        $ExpectedResponseCode,
        [Parameter(Mandatory = $true)]
        [string]
        $runLocation,
        [Parameter(Mandatory = $true)]
        [string]
        $InstrumentationKey,
        [Parameter(Mandatory = $true)]
        [string]
        $IngestionEndpoint
    )

    # Create a new GUID for the operation ID we pass to App Insights
    $OperationId = (New-Guid).ToString("N");

    # Set our 'success' field to false as default
    $BaseDataSuccess = $false

    # Start a timer for the url test
    $Stopwatch = [System.Diagnostics.Stopwatch]::New()
    $Stopwatch.Start()

    # Perform the test call in a try-catch
    $OriginalErrorActionPreference = $ErrorActionPreference
    Try {
        Write-Output "Executing test url call"
        $ErrorActionPreference = "Stop"
        # Run test

        Write-Output "Calling $TestUrl with HostHeader $HostHeader"
        $Response = Invoke-WebRequest -Method $Method -uri $TestUrl -UseBasicParsing
        
        if ($Response.StatusCode -eq $ExpectedResponseCode) {
            $BaseDataSuccess = $true
            $BaseDataMessage = 'passed'
        }
        # End test
    }
    Catch {
        # Put the exception message into what's passed to ApplicationInsights
        $BaseDataMessage = $_.Exception.Message
        if ($_.Exception.Response.StatusCode -eq $ExpectedResponseCode) {
            $BaseDataSuccess = $true
        }
    }
    Finally {
        $Stopwatch.Stop()
        $BaseDataDuration = $Stopwatch.ElapsedMilliseconds
        $BaseDataTimestamp = [DateTimeOffset]::UtcNow
        $ErrorActionPreference = $OriginalErrorActionPreference
    }

    # Build the object to sent to ApplicationInsights
    $tags = New-Object PSObject
    Add-Member -InputObject $tags -NotePropertyName ai.cloud.roleInstance -NotePropertyValue $runLocation

    $properties = New-Object PSObject
    Add-Member -InputObject $properties -NotePropertyName Target -NotePropertyValue $HostHeader
    Add-Member -InputObject $properties -NotePropertyName UrlPath -NotePropertyValue $UrlPath
    Add-Member -InputObject $properties -NotePropertyName Host -NotePropertyValue $runLocation
    Add-Member -InputObject $properties -NotePropertyName Source -NotePropertyValue $runLocation

    $metrics = New-Object PSObject
    # Add-Member -InputObject $properties NoteProperty propName 'propValue'

    $basedata = New-Object PSObject
    Add-Member -InputObject $basedata -NotePropertyName ver -NotePropertyValue 2
    Add-Member -InputObject $basedata -NotePropertyName name -NotePropertyValue $Name
    Add-Member -InputObject $basedata -NotePropertyName id -NotePropertyValue $OperationId
    Add-Member -InputObject $basedata -NotePropertyName runLocation -NotePropertyValue $runLocation
    Add-Member -InputObject $basedata -NotePropertyName success -NotePropertyValue $BaseDataSuccess
    Add-Member -InputObject $basedata -NotePropertyName message -NotePropertyValue $BaseDataMessage
    Add-Member -InputObject $basedata -NotePropertyName duration -NotePropertyValue $BaseDataDuration
    Add-Member -InputObject $basedata -NotePropertyName properties -NotePropertyValue $properties
    Add-Member -InputObject $basedata -NotePropertyName metrics -NotePropertyValue $metrics

    $data = New-Object PSObject
    Add-Member -InputObject $data -NotePropertyName baseType -NotePropertyValue 'AvailabilityData'
    Add-Member -InputObject $data -NotePropertyName baseData -NotePropertyValue $basedata


    $body = New-Object PSObject
    Add-Member -InputObject $body -NotePropertyName name -NotePropertyValue 'Microsoft.ApplicationInsights.Event'
    Add-Member -InputObject $body -NotePropertyName time -NotePropertyValue $($BaseDataTimestamp.ToString('o'))
    Add-Member -InputObject $body -NotePropertyName iKey -NotePropertyValue $InstrumentationKey
    Add-Member -InputObject $body -NotePropertyName tags -NotePropertyValue $tags
    Add-Member -InputObject $body -NotePropertyName data -NotePropertyValue $data

    # Convert the object to json
    $sendbody = ConvertTo-Json -InputObject $body -Depth 5

    Write-Output "Sending data to ApplicationInsights"

    Invoke-WebRequest -Uri "$IngestionEndpoint/v2/track" -Method 'POST' -UseBasicParsing -body $sendbody
}


# Load the json control file
Write-Output "Loading Control File"
$AvailablityCheckControl = Get-Content -Path "$PsScriptRoot\AppInsightsControl.json" -Raw | ConvertFrom-Json

# Get the InstrumentationKey and ingestionendpoint from the connectionstring
$InstrumentationKey = $AvailablityCheckControl.ConnectionString.Split(';')[0].split('=')[1]
$IngestionEndpoint = $AvailablityCheckControl.ConnectionString.Split(';')[1].split('=')[1].trim('/')

# Get the local computer name to pass in as the test location
$CloudRoleInstance = $env:COMPUTERNAME

# Loop through all the services in the control file that we need to call
foreach ($AvailabilityTest in $AvailablityCheckControl.AvailabilityTests) {
    Write-Output $AvailabilityTest
    if ($AvailabilityTest.NoTLS) {
        $Protocol = "http://"
    }
    else {
        $Protocol = "https://"
    }
    
    $TargetFQDN = $AvailabilityTest.FQDN
    
    if ($AvailabilityTest.Port) {
        $BaseUrl = "$Protocol$($TargetFQDN):$($AvailabilityTest.Port)"
    }
    else {
        $BaseUrl = "$Protocol$($TargetFQDN)"
    }

    foreach ($UrlPath in $AvailabilityTest.UrlPath) {
        $TestUrl = "$BaseUrl/$($UrlPath.trimstart('/'))"

        Write-Output "Calling $TestUrl"

        Send-AvailabilityResult -Name $AvailabilityTest.Name -TestUrl $TestUrl -UrlPath $UrlPath -Method $AvailabilityTest.Method -ExpectedResponseCode $AvailabilityTest.ExpectedResponseCode -runLocation $CloudRoleInstance -InstrumentationKey $InstrumentationKey -IngestionEndpoint $IngestionEndpoint
    }
}







# Data formats for ref
# {
#     "name": "Microsoft.ApplicationInsights.Availability",
#     "time": "2015-05-21T16:43:14.4670675-06:00",
#     "iKey": "[MyInstrumentationKey]",
#     "tags": {
#     },
#     "data": {
#        "baseType": "AvailabilityData",
#        "baseData": {
#           "ver": 2,
#           "name": "SampleAvailability",
#           "duration": "timespan",
#           "runlocation": "UK",
#           "success": true,
#           "message": "error message",
#           "properties": {
#              "x": "value x",
#              "y": "value y",
#              "z": "value z"
#           },
#           "metrics": [
#              {
#                 "name": "BasicMetric",
#                 "kind": "Measurement",
#                 "value": 42
#              }
#           ]
#        }
#     }
#  }