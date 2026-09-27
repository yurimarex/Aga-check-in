$port = 8000
$root = $PSScriptRoot

function Open-Sistema {
    $chromePaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    $chrome = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($chrome) {
        Start-Process -FilePath $chrome -ArgumentList "http://localhost:$port/"
    } else {
        Start-Process "http://localhost:$port/"
    }
}

# Verifica se o sistema ja esta rodando (de uma janela aberta anteriormente)
$jaRodando = $false
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("localhost", $port)
    $tcp.Close()
    $jaRodando = $true
} catch {}

if ($jaRodando) {
    Write-Host "O sistema ja esta aberto em outra janela."
    Write-Host "Abrindo uma aba com ele, sem iniciar um novo servidor..."
    Open-Sistema
    Start-Sleep -Seconds 2
    exit
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
} catch {
    Write-Host ""
    Write-Host "============================================================"
    Write-Host " Nao foi possivel abrir a porta $port."
    Write-Host " Feche outras janelas pretas abertas e tente de novo."
    Write-Host "============================================================"
    Write-Host ""
    pause
    exit
}

Write-Host "Servidor rodando em http://localhost:$port"
Write-Host "NAO FECHE esta janela enquanto estiver usando o sistema."
Write-Host "Para desligar o servidor, feche esta janela."
Write-Host ""

Start-Sleep -Seconds 1
Open-Sistema

$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".ico"  = "image/x-icon"
    ".txt"  = "text/plain; charset=utf-8"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath
        if ($path -eq "/") { $path = "/index.html" }
        $relative = $path.TrimStart("/") -replace "/", "\"
        $filePath = Join-Path $root $relative

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath)
            $contentType = $mime[$ext]
            if (-not $contentType) { $contentType = "application/octet-stream" }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - Arquivo nao encontrado: $path")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }
        $response.OutputStream.Close()
    } catch {
        Write-Host "Erro ao atender pedido: $_"
    }
}
