param(
  [Parameter(Mandatory = $true)]
  [string]$Target,
  [int]$LocalPort = 18080,
  [int]$RemotePort = 31880
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\open-jetson-novnc-tunnel.ps1" $Target $LocalPort $RemotePort
