Set-StrictMode -Version Latest

$script:status = @{}

function Get-Epoch{
  $UNIX_EPOCH = Get-Date("1970/1/1 0:0:0 GMT")
  return ((Get-Date) - $UNIX_EPOCH).TotalMilliseconds
}
function Period-Remaining($Name, $Period){
  $elapsed = (Get-Epoch) - $script:status.$Name.last_reset
  return ($Period - $elapsed)
}

function Invoke-WithRateLimited {
  param(
    [string]$Name = 'RateLimit-default',
    [int]$Calls = 10,
    [int]$Period = 1000,
    [switch]$Throw = $false,
    [Parameter(Mandatory=$true, Position=0)]
    [scriptblock]$Action
  )

  $mutex = New-Object System.Threading.Mutex($false, $Name)
  $mutex.WaitOne() | Out-Null
  if( -not $script:status.ContainsKey($Name)){
    $script:status.Add($Name, @{num_calls = 0; last_reset = Get-Epoch })
  }

  $period_remaining = Period-Remaining -Name $Name -Period $Period
  if($period_remaining -le 0){
    $script:status.$Name.num_calls = 0
    $script:status.$Name.last_reset = Get-Epoch
  }
  $script:status.$Name.num_calls++ | Out-Null
  Write-Debug "Name: $Name  num_calls: $($script:status.$Name.num_calls)  reminining:$($period_remaining)"
  if($script:status.$Name.num_calls -gt $Calls){
    if($Throw){
      Throw "Num calls exceeded."
    } else {
      Write-Verbose "exceeded. sleep $($period_remaining) milliseconds and reset num_calls."
      Start-Sleep -milliseconds ($period_remaining)
      $script:status.$Name.num_calls = 1
      $script:status.$Name.last_reset = Get-Epoch
    }
  }

  $Action.Invoke() | Write-Output
  $mutex.ReleaseMutex() | Out-Null
}

Export-ModuleMember -Function Invoke-WithRateLimited
