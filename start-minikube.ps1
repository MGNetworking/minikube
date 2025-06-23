# Execution admin requise
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERREUR : Ce script doit etre lance en tant qu'administrateur."
    exit 1
}

# Fichier hosts
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"

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

# Validation de l'IP
if (-not ($minikubeIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')) {
    Write-Host "ERREUR : IP Minikube invalide ($minikubeIP). Impossible de mettre a jour le fichier hosts."
    exit 1
}

# Nouvelle entree pour le fichier hosts
$newEntry = "$minikubeIP nutrition.local gateway.local"

# Mise a jour du fichier hosts avec retries
$maxRetries = 5
$retryDelay = 2 # secondes
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        # Lecture du fichier hosts
        $hostsContent = Get-Content -Path $hostsFile -ErrorAction Stop
        $entryIndex = -1
        $needsUpdate = $false

        # Recherche de l'entree existante
        for ($i = 0; $i -lt $hostsContent.Count; $i++) {
            if ($hostsContent[$i] -match '\s+nutrition\.local\s+gateway\.local\s*$') {
                $entryIndex = $i
                # Verifier si l'entree est correcte
                if ($hostsContent[$i] -ne $newEntry) {
                    $needsUpdate = $true
                }
                break
            }
        }

        # Mise a jour ou ajout de l'entree si necessaire
        if ($entryIndex -ge 0 -and $needsUpdate) {
            Write-Host "Mise a jour de l'entree existante dans le fichier hosts..."
            $hostsContent[$entryIndex] = $newEntry
            Set-Content -Path $hostsFile -Value $hostsContent -Force -Encoding ASCII -ErrorAction Stop
            Write-Host "Fichier hosts mis a jour avec succes : $newEntry"
        } elseif ($entryIndex -eq -1) {
            Write-Host "Ajout d'une nouvelle entree dans le fichier hosts..."
            $hostsContent += $newEntry
            Set-Content -Path $hostsFile -Value $hostsContent -Force -Encoding ASCII -ErrorAction Stop
            Write-Host "Fichier hosts mis a jour avec succes : $newEntry"
        } else {
            Write-Host "L'entree dans le fichier hosts est deja correcte : $newEntry"
        }

        $success = $true
    } catch {
        $retryCount++
        if ($retryCount -eq $maxRetries) {
            Write-Host "ERREUR : Impossible de mettre à jour le fichier hosts après $maxRetries tentatives : $_"
            exit 1
        }
        Write-Host "Fichier hosts verrouille, nouvelle tentative dans $retryDelay secondes ($retryCount/$maxRetries)..."
        Start-Sleep -Seconds $retryDelay
    }
}