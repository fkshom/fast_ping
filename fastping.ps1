try {
    Import-Module .\Invoke-WithRateLimited.psm1
    Import-Module .\Ping-MultipleHosts.psm1

    $DebugPreference = 'Continue'
    $VerbosePreference = 'Continue'
    $hosts = @()

    $hosts += 1..250 | % {
      "192.168.1.$_"
    }

    Measure-Command {
        $hosts | Ping-MultipleHosts -Rate 5 -Period 100 | ForEach-Object {
            write-host $_
        }
    }
}
finally {
    $DebugPreference = 'SilentlyContinue'
    $VerbosePreference = 'SilentlyContinue'
    Remove-Module Invoke-WithRateLimited
    Remove-Module Ping-MultipleHosts
}