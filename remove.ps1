# delete-minikube.ps1
# Script to completely remove Minikube, Hyper-V, and related configurations

# Force UTF-8 encoding
Write-Host "Force UTF-8 encoding for the script ..."
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Step 1: Run minikube delete first
Write-Host "Step 1: Run minikube delete ..."
try {
    minikube delete --all --purge
    Write-Host "Minikube configuration deleted successfully."
} catch {
    Write-Host "Error during minikube delete: $_"
}

# Step 2: Stop and remove the Minikube VM (in case anything remains)
Write-Host "Step 2: Remove the Minikube VM ..."
Stop-VM -Name "minikube" -Force -ErrorAction SilentlyContinue
Remove-VM -Name "minikube" -Force -ErrorAction SilentlyContinue

# Step 3: Remove the Minikube configuration folder
Write-Host "Step 3: Remove the Minikube configuration folder ..."
Remove-Item -Path "$env:USERPROFILE\.minikube" -Recurse -Force -ErrorAction SilentlyContinue

# Step 4: Remove Minikube virtual disks
Write-Host "Step 4: Remove Minikube virtual disks ..."
$hyperVPath = "C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks"
if (Test-Path $hyperVPath) {
    Get-ChildItem -Path $hyperVPath -Filter "*minikube*.vhdx" | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Step 5: Remove the MinikubeSwitch virtual switch
Write-Host "Step 5: Remove the MinikubeSwitch virtual switch ..."
Remove-VMSwitch -Name "MinikubeSwitch" -Force -ErrorAction SilentlyContinue

# Step 6: Disable VMware adapters to avoid conflicts
Write-Host "Step 6: Disable VMware adapters ..."
Get-NetAdapter -Name "VMware*" | Disable-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "Complete cleanup finished! Everything is removed."