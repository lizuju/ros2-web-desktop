param(
    [Parameter(Mandatory = $true)]
    [string]$Target,

    [int]$LocalPort = 18080,

    [int]$RemotePort = 31880
)

Write-Host "Opening SSH tunnel:"
Write-Host "  http://localhost:$LocalPort/vnc.html -> ${Target}:127.0.0.1:$RemotePort"
Write-Host "Keep this PowerShell window open. Press Ctrl+C to close the tunnel."

ssh -N -L "127.0.0.1:${LocalPort}:127.0.0.1:${RemotePort}" $Target
