Set-StrictMode -Version Latest

Import-Module .\Invoke-WithRateLimited.psm1

Function Get-IPAddressRange{
    param(
        [IPAddress]$StartAddress,
        [IPAddress]$EndAddress
    )

    $IPArray = @()

    $Start = $StartAddress.GetAddressBytes()
    [Array]::Reverse($Start)
    $Start = ([IPAddress]($Start -join '.')).Address

    $End = $EndAddress.GetAddressBytes()
    [Array]::Reverse($End)
    $End = ([IPAddress]($End -join '.')).Address

    for ($i = $Start; $i -le $End; $i++) {
        $IP = ([IPAddress]$i).GetAddressBytes()
        [Array]::Reverse($IP)
        $IPArray += $IP -join '.'  
    }
    return $IPArray
}

# inspired by https://gallery.technet.microsoft.com/scriptcenter/Most-faster-ping-of-a2e26929
function Ping-MultipleHosts {
    
    [cmdletbinding()]
    param (
        
        [parameter (Position = 0, 
                    Mandatory = $True, 
                    ParameterSetName = 'Comp', 
                    ValueFromPipeline=$True)]
        [Alias ('ComputerName','Name')]
        [string[]]$HostName,

        [parameter (Mandatory = $True, 
                    ParameterSetName = 'Range')]
        [IPAddress]$StartAddress,

        [parameter (Mandatory = $True, 
                    ParameterSetName = 'Range')]
        [IPAddress]$EndAddress,

        [int]$Timeout = 2000,

        [switch]$DontFragment,

        [int]$BufferSize = 32,

        [int]$Rate = 10,

        [int]$Period = 100
    )

    begin {

        $global:PingResultCount = 0
        $InputObjects = @()

        if ($StartAddress) {
            $Hostname = @(Get-IPAddressRange -StartAddress $StartAddress -EndAddress $EndAddress)
        }
    
    }

    process {
        $InputObjects += @($HostName)
    }

    end {

        $DF = New-Object Net.NetworkInformation.PingOptions
        if ($DontFragment) {      
            $DF.DontFragment = $true
        }
        else {
            $DF.DontFragment = $false
        }

        $global:ResultQueue = New-Object System.Collections.Concurrent.ConcurrentQueue[pscustomobject]

        $InputObjects | ForEach-Object {
            $Ping = New-Object System.Net.NetworkInformation.Ping

            Register-ObjectEvent $Ping PingCompleted -Action {
                $global:PingResultCount++ | Out-Null
                $result = [pscustomobject][ordered]@{
                    Host = $event.SourceArgs[1].UserState
                    Status = $event.SourceArgs[1].Reply.Status
                    Time = $event.SourceArgs[1].Reply.RoundtripTime
                    Address = $event.SourceArgs[1].Reply.Address
                }
                $global:ResultQueue.Enqueue($result) | Out-Null
            } | Out-Null

            Invoke-WithRateLimited -Name ping -Calls $Rate -Period $Period {
              $Ping.SendAsync($_, $Timeout, (New-Object Byte[] $BufferSize), $DF, $_) | Out-Null
            }
            $result = $null
            while($global:ResultQueue.TryDequeue([ref]$result)){
              $result | Write-Output
            }
        }

        while ($global:PingResultCount -lt $InputObjects.Count) {
            $result = $null
            while($global:ResultQueue.TryDequeue([ref]$result)){
              $result | Write-Output
            }
            Start-Sleep -Milliseconds 10 | Out-Null
        }
    }
}

Export-ModuleMember -Function Ping-MultipleHosts
