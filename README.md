# fast_ping
Fast Ping using Powershell

## How to use

```
Import-Module .\Ping-MultipleHosts.psm1
$hosts = @()
$hosts += 1..250 | % {
  "192.168.1.$_"
}
Measure-Command {
    $hosts | Ping-MultipleHosts -Rate 5 -Period 100 | ForEach-Object {
        write-host $_
    }
}
```

```
@{Host=192.168.1.1; Status=Success; Time=0; Address=192.168.1.1}
@{Host=192.168.1.28; Status=DestinationHostUnreachable; Time=0; Address=192.168.1.80}
@{Host=192.168.1.27; Status=DestinationHostUnreachable; Time=0; Address=192.168.1.80}
@{Host=192.168.1.26; Status=DestinationHostUnreachable; Time=0; Address=192.168.1.80}
@{Host=192.168.1.25; Status=DestinationHostUnreachable; Time=0; Address=192.168.1.80}
@{Host=192.168.1.24; Status=DestinationHostUnreachable; Time=0; Address=192.168.1.80}
@{Host=192.168.1.23; Status=DestinationHostUnreachable; Time=0; Address=192.168.1.80}
@{Host=192.168.1.22; Status=DestinationHostUnreachable; Time=0; Address=192.168.1.80}

(snip...)


Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 6
Milliseconds      : 747
Ticks             : 67473974
TotalDays         : 7.80948773148148E-05
TotalHours        : 0.00187427705555556
TotalMinutes      : 0.112456623333333
TotalSeconds      : 6.7473974
TotalMilliseconds : 6747.3974
```
