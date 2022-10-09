# Function that will call AppInsights
function Send-CustomEvent {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,
        [Parameter(Mandatory = $true)]
        [string]
        $CustomPropertyValue,
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

    #Grab the current time for our event timestamp
    $BaseDataTimestamp = [DateTimeOffset]::UtcNow
    
    # Build the object to sent to ApplicationInsights
    $tags = New-Object PSObject
    Add-Member -InputObject $tags -NotePropertyName ai.cloud.roleInstance -NotePropertyValue $runLocation

    $properties = New-Object PSObject
    Add-Member -InputObject $properties -NotePropertyName MyCustomProperty -NotePropertyValue $CustomPropertyValue

    $basedata = New-Object PSObject
    Add-Member -InputObject $basedata -NotePropertyName ver -NotePropertyValue 2
    Add-Member -InputObject $basedata -NotePropertyName name -NotePropertyValue $Name
    #Add-Member -InputObject $basedata -NotePropertyName id -NotePropertyValue $OperationId

    Add-Member -InputObject $basedata -NotePropertyName properties -NotePropertyValue $properties


    $data = New-Object PSObject
    Add-Member -InputObject $data -NotePropertyName baseType -NotePropertyValue 'EventData'
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
foreach ($Event in $AvailablityCheckControl.Events) {
    Send-CustomEvent -Name $Event.Name -CustomPropertyValue $Event.CustomPropertyValue -runLocation $CloudRoleInstance -InstrumentationKey $InstrumentationKey -IngestionEndpoint $IngestionEndpoint
}

# Data formats for ref
# {
#     "name": "Microsoft.ApplicationInsights.Event",
#     "time": "2015-05-21T16:43:14.4670675-06:00",
#     "iKey": "[MyInstrumentationKey]",
#     "tags": {
#     },
#     "data": {
#        "baseType": "EventData",
#        "baseData": {
#           "ver": 2,
#           "name": "SampleEvent",
#           "properties": {
#              "x": "value x",
#              "y": "value y",
#              "z": "value z"
#           }
#        }
#     }
#  }