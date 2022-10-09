# Data formats for reference

## CustomEvent
```json
{
    "name": "Microsoft.ApplicationInsights.Event",
    "time": "2015-05-21T16:43:14.4670675-06:00",
    "iKey": "[MyInstrumentationKey]",
    "tags": {
    },
    "data": {
       "baseType": "EventData",
       "baseData": {
          "ver": 2,
          "name": "SampleEvent",
          "properties": {
             "x": "value x",
             "y": "value y",
             "z": "value z"
          }
       }
    }
}
```

## Trace
```json
{
    "name": "Microsoft.ApplicationInsights.Event",
    "time": "2021-02-25T21:35:45.0000000Z",
    "iKey": "[MyInstrumentationKey]",
    "tags":{
    },
    "data": {
       "baseType": "MessageData",
       "baseData": {
          "ver": 2,
          "message": "Simple Trace Log Message",
          "severityLevel": 2,
          "properties": {
             "x": "value x",
             "y": "value y",
             "z": "value z"
          }
       }
    }
}
```
level 0 = "Verbose"
level 1 = "Information"
level 2 = "Warning"
level 3 = "Error"
level 4 = "Critical"

## CustomMetric
```json
{
    "name": "Microsoft.ApplicationInsights.Event",
    "time": "2021-02-25T21:35:45.0000000Z",
    "iKey": "[MyInstrumentationKey]",
    "tags": {
    },
    "data": {
       "baseType": "MetricData",
       "baseData": {
          "ver": 2,
          "metrics": [
             {
                "name": "BasicMetric",
                "kind": "Measurement",
                "value": 42
             }
          ],
          "properties": {
             "x": "value x",
             "y": "value y",
             "z": "value z"
          }
       }
    }
}
```

## Exception
```json
{
    "name": "Microsoft.ApplicationInsights.Event",
    "time": "2021-02-25T21:35:45.0000000Z",
    "iKey": "[MyInstrumentationKey]",
    "tags": {
    },
    "data": {
       "baseType": "ExceptionData",
       "baseData": {
          "ver": 2,
          "handledAt": "UserCode",
          "properties": {
             "x": "value x",
             "y": "value y",
             "z": "value z"
          },
          "exceptions": [
             {
                "id": 26756241,
                "typeName": "System.Exception",
                "message": "Something bad has happened!",
                "hasFullStack": true,
                "parsedStack": [
                   {
                      "level": 0,
                      "method": "Console.Program.Main",
                      "assembly": "Console, Version=1.0",
                      "fileName": "/ApplicationInsights/Test.cs",
                      "line": 42
                   }
                ]
             }
          ]
       }
    }
}
```

## AvailabilityResult
```json
{
    "name": "Microsoft.ApplicationInsights.Availability",
    "time": "2015-05-21T16:43:14.4670675-06:00",
    "iKey": "[MyInstrumentationKey]",
    "tags": {
    },
    "data": {
       "baseType": "AvailabilityData",
       "baseData": {
          "ver": 2,
          "name": "SampleAvailability",
          "duration": "timespan",
          "runlocation": "UK",
          "success": true,
          "message": "error message",
          "properties": {
             "x": "value x",
             "y": "value y",
             "z": "value z"
          },
          "metrics": [
             {
                "name": "BasicMetric",
                "kind": "Measurement",
                "value": 42
             }
          ]
       }
    }
}
```