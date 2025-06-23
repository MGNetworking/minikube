# Execution admin requise
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERREUR : Ce script doit etre lance en tant qu'administrateur."
    exit 1
}

# Fichier hosts
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$ipLinePattern = "^192\.168\.1\.\d+\s+nutrition\.local\s+gateway\.local$"

# Etat de la VM
$vm = Get-VM -Name "minikube" -ErrorAction SilentlyContinue
$vmState = if ($vm) { $vm.State } else { "Absent" }

# Demarrage si la VM n'est pas en cours
if ($vmState -eq "Running") {
    Write-Host "La VM 'minikube' est deja en cours. Mise a jour du fichier hosts uniquement..."
    $minikubeIP = minikube ip
} else {
    Write-Host "Demarrage de Minikube..."
    minikube start --driver=hyperv --hyperv-virtual-switch=MinikubeSwitch --force

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERREUR : Echec du demarrage de Minikube."
        exit 1
    }

    $minikubeIP = minikube ip
}

Write-Host "IP detectee : $minikubeIP"

# Lecture du fichier hosts
$hostsContent = Get-Content -Path $hostsFile
$entryIndex = -1

for ($i = 0; $i -lt $hostsContent.Count; $i++) {
    if ($hostsContent[$i] -match $ipLinePattern) {
        $entryIndex = $i
        break
    }
}

# Mise a jour ou ajout de l'entree
$newEntry = "$minikubeIP nutrition.local gateway.local"
if ($entryIndex -ge 0) {
    Write-Host "Mise a jour de l'entree existante dans le fichier hosts..."
    $hostsContent[$entryIndex] = $newEntry
} else {
    Write-Host "Ajout d'une nouvelle entree dans le fichier hosts..."
    $hostsContent += $newEntry
}

# Ecriture du fichier
Set-Content -Path $hostsFile -Value $hostsContent -Force -Encoding UTF8

Write-Host "Fichier hosts mis a jour avec succes : $newEntry"
