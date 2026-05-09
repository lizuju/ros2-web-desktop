param(
    [Parameter(Mandatory = $true)]
    [string]$Target,

    [int]$LocalPort = 18080,

    [int]$RemotePort = 0,

    [string]$RemoteProjectDir = $env:REMOTE_PROJECT_DIR
)

if ([string]::IsNullOrWhiteSpace($RemoteProjectDir)) {
    $RemoteProjectDir = "~/ros2-web-desktop"
}

function Test-LocalPortFree {
    param([int]$Port)

    $listener = $null
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
        return $true
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $listener) {
            $listener.Stop()
        }
    }
}

function Find-FreeLocalPort {
    param([int]$StartPort)

    $port = $StartPort
    while (-not (Test-LocalPortFree -Port $port)) {
        $port += 1
    }
    return $port
}

if ($RemotePort -eq 0) {
    $remoteCommand = "sed -n 's/^NOVNC_PORT=//p' $RemoteProjectDir/.env 2>/dev/null | tail -n 1"
    $remoteValue = (& ssh $Target $remoteCommand 2>$null | Select-Object -Last 1)
    if ([string]::IsNullOrWhiteSpace($remoteValue)) {
        Write-Host "Could not read NOVNC_PORT from ${Target}:$RemoteProjectDir/.env"
        Write-Host "Pass -RemotePort explicitly, or set -RemoteProjectDir."
        Write-Host "Example: .\scripts\open-ros2-novnc-tunnel.ps1 $Target -LocalPort $LocalPort -RemotePort 31880"
        exit 1
    }
    $RemotePort = [int]$remoteValue
}

$LocalPort = Find-FreeLocalPort -StartPort $LocalPort
$Url = "http://localhost:$LocalPort/vnc.html"

Write-Host "Opening SSH tunnel:"
Write-Host "  $Url -> ${Target}:127.0.0.1:$RemotePort"
Write-Host "Remote project directory: $RemoteProjectDir"
Write-Host "Keep this PowerShell window open. Press Ctrl+C to close the tunnel."

$job = Start-Job -ScriptBlock {
    param([int]$Port, [string]$Url)

    for ($i = 0; $i -lt 60; $i++) {
        $client = $null
        try {
            $client = [System.Net.Sockets.TcpClient]::new("127.0.0.1", $Port)
            Start-Process $Url
            return
        }
        catch {
            Start-Sleep -Seconds 1
        }
        finally {
            if ($null -ne $client) {
                $client.Close()
            }
        }
    }

    Write-Host "Open: $Url"
} -ArgumentList $LocalPort, $Url

try {
    ssh -N -o ExitOnForwardFailure=yes -L "127.0.0.1:${LocalPort}:127.0.0.1:${RemotePort}" $Target
}
finally {
    Remove-Job $job -Force -ErrorAction SilentlyContinue
}
