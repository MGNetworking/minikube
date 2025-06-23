# Execution admin requise
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERREUR : Ce script doit etre lance en tant qu'administrateur."
    exit 1
}

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