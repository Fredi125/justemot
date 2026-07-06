#Requires -Version 5.1
<#
  televerser.ps1 - transfere le paquet vers le VPS puis l'extrait a distance.
  Ecrit en ASCII pur pour fonctionner sous Windows PowerShell 5.1 quel que
  soit l'encodage du fichier.

  Prerequis : client OpenSSH (inclus dans Windows 10/11).

  Usage, depuis le dossier qui contient aujustemotcnv.zip :
      .\televerser.ps1
  Ou en pointant le zip explicitement :
      .\televerser.ps1 -Zip "C:\chemin\vers\aujustemotcnv.zip"
  Ou en changeant la cible :
      .\televerser.ps1 -VpsUser deploy -VpsHost 192.99.68.47

  Ensuite, en SSH sur le VPS :
      cd /tmp/aujustemotcnv-paquet/deploiement
      bash deployer-serveur.sh
#>
param(
    [string]$VpsUser   = "deploy",
    [string]$VpsHost   = "192.99.68.47",
    [string]$Zip       = "aujustemotcnv.zip",
    [string]$RemoteTmp = "/tmp/aujustemotcnv-paquet"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Zip)) {
    throw "Fichier introuvable : $Zip. Lance le script depuis le dossier contenant le zip, ou passe -Zip avec le chemin complet."
}

$target  = "$VpsUser@$VpsHost"
$zipName = Split-Path -Leaf $Zip

Write-Host "==> 1/2  Transfert de $Zip vers ${target}:/tmp/ ..." -ForegroundColor Cyan
scp $Zip "${target}:/tmp/"
if ($LASTEXITCODE -ne 0) { throw "Echec du transfert scp (code $LASTEXITCODE)." }

Write-Host "==> 2/2  Extraction a distance dans $RemoteTmp ..." -ForegroundColor Cyan
$remote = "rm -rf $RemoteTmp && mkdir -p $RemoteTmp && unzip -o /tmp/$zipName -d $RemoteTmp > /dev/null && echo EXTRACTION_OK"
ssh $target $remote
if ($LASTEXITCODE -ne 0) { throw "Echec de l'extraction distante (code $LASTEXITCODE)." }

Write-Host ""
Write-Host "Paquet transfere et extrait sur le VPS." -ForegroundColor Green
Write-Host "Prochaine etape - en SSH sur le VPS :" -ForegroundColor Yellow
Write-Host "    cd $RemoteTmp/deploiement && bash deployer-serveur.sh"
