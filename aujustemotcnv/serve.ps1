<#
    serve.ps1 — petit serveur statique pour tester « Au juste mot » en local.

    Pourquoi : un service worker et l'installation d'une PWA exigent un « contexte
    securise ». http://localhost en fait partie : pas besoin de certificat HTTPS pour
    tester sur ta propre machine. (Pour Tommy, sur son telephone, il faudra un vrai
    hebergement HTTPS — voir le LISEZMOI.)

    Utilisation (dans le dossier de l'app) :
        powershell -ExecutionPolicy Bypass -File .\serve.ps1
    puis ouvre http://localhost:8080/ dans Chrome/Edge.
    Compatible Windows PowerShell 5.1 et PowerShell 7+.
#>

param(
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if ([string]::IsNullOrEmpty($root)) { $root = (Get-Location).Path }

$mime = @{
    '.html'        = 'text/html; charset=utf-8'
    '.js'          = 'text/javascript; charset=utf-8'
    '.json'        = 'application/json; charset=utf-8'
    '.webmanifest' = 'application/manifest+json; charset=utf-8'
    '.css'         = 'text/css; charset=utf-8'
    '.png'         = 'image/png'
    '.ico'         = 'image/x-icon'
    '.svg'         = 'image/svg+xml'
    '.woff2'       = 'font/woff2'
    '.txt'         = 'text/plain; charset=utf-8'
}

$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "Impossible d'ouvrir le port $Port. Essaie un autre port :" -ForegroundColor Red
    Write-Host "    .\serve.ps1 -Port 8090" -ForegroundColor Yellow
    throw
}

Write-Host ""
Write-Host "  Au juste mot — serveur local actif" -ForegroundColor Green
Write-Host "  Dossier : $root"
Write-Host "  URL     : $prefix" -ForegroundColor Cyan
Write-Host "  (Ctrl+C pour arreter)"
Write-Host ""

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response

        $rel = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
        if ([string]::IsNullOrEmpty($rel)) { $rel = 'index.html' }
        $path = Join-Path $root $rel

        if ((Test-Path $path -PathType Container)) {
            $path = Join-Path $path 'index.html'
        }

        if (Test-Path $path -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
            if ($mime.ContainsKey($ext)) { $ctype = $mime[$ext] } else { $ctype = 'application/octet-stream' }
            $bytes = [System.IO.File]::ReadAllBytes($path)
            $res.StatusCode = 200
            $res.ContentType = $ctype
            # le SW doit toujours etre revalide
            if ($ext -eq '.js' -or $ext -eq '.webmanifest') {
                $res.Headers.Add('Cache-Control', 'no-cache')
            }
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
            Write-Host ("  200  {0}" -f $rel)
        } else {
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 - introuvable : $rel")
            $res.StatusCode = 404
            $res.ContentType = 'text/plain; charset=utf-8'
            $res.ContentLength64 = $msg.Length
            $res.OutputStream.Write($msg, 0, $msg.Length)
            Write-Host ("  404  {0}" -f $rel) -ForegroundColor DarkYellow
        }
        $res.OutputStream.Close()
    }
} finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Serveur arrete." -ForegroundColor Green
}
