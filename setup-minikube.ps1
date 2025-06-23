# setup-minikube.ps1
# Script to set up Minikube with Hyper-V, using Ethernet 2 for the virtual switch

$line = "-------------------------------------------"
$macAddress = "00-15-5D-01-03-04"

Write-Host "$line"
Write-Host "Step 1: Clean Minikube files"
$minikubePath = "$env:USERPROFILE\.minikube"
if (Test-Path $minikubePath) {
    Write-Host "Deleting $minikubePath..."
    Remove-Item -Path $minikubePath -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "$line"
Write-Host "Step 2: Verify Docker Desktop"
try {
    docker ps | Out-Null
    Write-Host "Docker is running on the host machine."
} catch {
    Write-Host "Error: Docker Desktop must be running. $_"
    exit 1
}

Write-Host "$line"
Write-Host "Step 3: Create Hyper-V switch"
$switchName = "MinikubeSwitch"
$desiredAdapterName = "Ethernet 2"
# Check if switch exists and is on the correct adapter
$existingSwitch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
$adapter = Get-NetAdapter -Name $desiredAdapterName -ErrorAction SilentlyContinue
if ($adapter -and $adapter.Status -eq "Up") {
    if ($existingSwitch -and $existingSwitch.NetAdapterInterfaceDescription -eq $adapter.InterfaceDescription) {
        Write-Host "Virtual switch $switchName already exists on $desiredAdapterName."
    } else {
        Write-Host "Creating or updating virtual switch $switchName on $desiredAdapterName..."
        Remove-VMSwitch -Name $switchName -Force -ErrorAction SilentlyContinue
        New-VMSwitch -Name $switchName -NetAdapterName $adapter.Name -AllowManagementOS $true
    }
} else {
    Write-Host "Error: $desiredAdapterName adapter is not available or not active. Check your Ethernet connection."
    exit 1
}

Write-Host "$line"
Write-Host "Step 4: Configure Hyper-V driver"
minikube config set driver hyperv

Write-Host "$line"
Write-Host "Step 5: Initial Minikube start"
minikube start --driver=hyperv --hyperv-virtual-switch=$switchName --cpus=4 --memory=8192 --disk-size=40g --force
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error during startup. See 'minikube logs --file=logs.txt'"
    exit 1
}

Write-Host "$line"
Write-Host "Step 6: Retrieve Minikube official IP"
$minikubeIP = & minikube ip
Write-Host "Minikube official IP detected: $minikubeIP"
if ([string]::IsNullOrEmpty($minikubeIP)) {
    Write-Host "Error: Unable to retrieve IP address."
    exit 1
}
Write-Host "Detected IP: $minikubeIP"

Write-Host "$line"
Write-Host "Step 7: Proper Minikube shutdown"
minikube stop

Write-Host "$line"
Write-Host "Step 8: Assign static MAC address"
try {
    Set-VMNetworkAdapter -VMName "minikube" -StaticMacAddress $macAddress -DhcpGuard Off -ErrorAction Stop
    Write-Host "Static MAC $macAddress assigned to Minikube VM"
} catch {
    Write-Host "Error assigning MAC: $_"
    exit 1
}

Write-Host "$line"
Write-Host "Step 9: Restart Minikube"
minikube start --driver=hyperv --hyperv-virtual-switch=$switchName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to restart Minikube with static MAC."
    exit 1
}

Write-Host "$line"
Write-Host "Step 10: Retrieve final Minikube IP (after static MAC)"
$minikubeIP = & minikube ip
Write-Host "Minikube official IP detected: $minikubeIP"
if ([string]::IsNullOrEmpty($minikubeIP)) {
    Write-Host "Error: Unable to retrieve IP address."
    exit 1
}
Write-Host "Detected IP: $minikubeIP"

Write-Host "$line"
Write-Host "Step 11: Verify Docker daemon"
Start-Sleep -Seconds 10
$dockerStatus = (minikube ssh "systemctl is-active docker").Trim()
if ($dockerStatus -ne "active") {
    Write-Host "Docker not active. Restarting..."
    minikube ssh "sudo systemctl restart docker"
    Start-Sleep -Seconds 5
    $dockerStatus = (minikube ssh "systemctl is-active docker").Trim()
    if ($dockerStatus -ne "active") {
        Write-Host "Error: Docker failed to start. Status: '$dockerStatus'"
        exit 1
    }
}
Write-Host "Docker is active in the VM."

Write-Host "$line"
Write-Host "Step 12: Update hosts file"
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$hostsEntry = "$minikubeIP nutrition.local gateway.local"
# Validate IP address
if (-not ($minikubeIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')) {
    Write-Host "Error: Invalid Minikube IP ($minikubeIP). Cannot update hosts file."
    exit 1
}
# Try to update hosts file with retries
$maxRetries = 5
$retryDelay = 2 # seconds
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $hostsContent = Get-Content -Path $hostsPath -ErrorAction Stop
        $newContent = $hostsContent | Where-Object { $_ -notmatch "nutrition.local|gateway.local" }
        Set-Content -Path $hostsPath -Value $newContent -ErrorAction Stop
        Add-Content -Path $hostsPath -Value "`n$hostsEntry" -ErrorAction Stop
        Write-Host "Hosts entry added: $hostsEntry"
        $success = $true
    } catch {
        $retryCount++
        if ($retryCount -eq $maxRetries) {
            Write-Host "Error updating hosts file after $maxRetries retries: $_"
            exit 1
        }
        Write-Host "Hosts file is locked, retrying in $retryDelay seconds ($retryCount/$maxRetries)..."
        Start-Sleep -Seconds $retryDelay
    }
}

Write-Host "$line"
Write-Host "Step 13: Configure local Docker"
& minikube -p minikube docker-env | Invoke-Expression

Write-Host "$line"
Write-Host "Step 14: Enable addons"
try {
    minikube addons enable registry
    minikube addons enable ingress
    Write-Host "Ingress and registry addons enabled"
} catch {
    Write-Host "Error enabling addons: $_"
    exit 1
}

Write-Host "$line"
Write-Host "Step 15: Final verification"
minikube status
kubectl cluster-info
kubectl get nodes

Write-Host "$line"
Write-Host "Minikube is ready with IP $minikubeIP and MAC $macAddress"