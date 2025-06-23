# Execution admin requise
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERREUR : Ce script doit etre lance en tant qu'administrateur."
    exit 1
}

# Fichier hosts
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$ipLinePattern = '^192\.168\.1\.\d+\s+nutrition\.local\s+gateway\.local$'

# Etat de la VM
$vm = Get-VM -Name "minikube" -ErrorAction SilentlyContinue
$vmState = if ($vm) { $vm.State } else { "Absent" }

# Arret de Minikube si la VM est en cours
if ($vmState -eq "Running") {
    Write-Host "Arret de la VM 'minikube'..."
    minikube stop

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERREUR : Echec de l'arret de Minikube."
        exit 1
    }
    Write-Host "Minikube arrete avec succes."
} else {
    Write-Host "La VM 'minikube' n'est pas en cours d'execution."
}

# Nettoyage de l'entree dans le fichier hosts
Write-Host "Nettoyage de l'entree hosts (nutrition.local gateway.local)..."
try {
    $originalLines = Get-Content -Path $hostsFile
    $filteredLines = $originalLines | Where-Object { $_ -notmatch $ipLinePattern }

    if ($filteredLines.Count -lt $originalLines.Count) {
        $filteredLines | Out-File -FilePath $hostsFile -Encoding ASCII
        Write-Host "Entree supprimee avec succes."
    } else {
        Write-Host "Aucune entree correspondante a supprimer."
    }
}
catch {
    Write-Host "ERREUR lors de la modification du fichier hosts : $_"
    exit 1
}
