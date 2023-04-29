Clear-Host

# Add Virtual Box bin-path to PATH environment variable if necessary
if ($null -eq (get-command VBoxManage.exe -errorAction silentlyContinue)) {
    $env:path="C:\Program Files\Oracle\VirtualBox;$env:path"
}
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

function Get-ConfigServerInformation {
    # Server information from config file
    # Read config directory
    $configFilesPath = "$scriptPath\configuration-files"
    if (! (test-path $configFilesPath)) {
        Write-Error "Config directory not found"
        Exit 0
    }
    [array]$configFiles = Get-ChildItem -Path "$configFilesPath" -Include *.json -Name

    Write-Host "================"
    Write-Host "CONFIG SELECTION"
    Write-Host "================"

    $counter = 1
    foreach ($config in $configFiles) {
        Write-Host "$counter. $config"
        $counter++
    }

    do {
        Write-Host "Choose an config file from the list: " -ForegroundColor Yellow -NoNewline
        $configFileChoice = Read-Host
    } until ($configFileChoice -in (1..$configFiles.Count))
    
    $global:configFilePath = "$configFilesPath\$($configFiles[$configFileChoice-1])"

    if (! (test-path $configFilePath)) {
        Write-Error "Config file not found"
        Exit 0
    }

    $configFile = Get-Content $configFilePath | ConvertFrom-Json

    #Variables
    $global:vmName                 = $configFile.vmName
    $global:osType                 = $configFile.osType
    $global:hdSizeMb               = $configFile.hdSizeMb
    $global:memSizeMb              = $configFile.memSizeMb
    $global:vramMb                 = $configFile.vramMb
    $global:nofCPUs                = $configFile.nofCPUs
    $global:fullUserName           = $configFile.fullUserName
    $global:username               = $configFile.username
    $global:password               = $configFile.password
    $global:isPostInstallationScript = $configFile.isPostInstallationScript
    $global:isPostConfigurationScript = $configFile.isPostConfigurationScript

    if ($isPostInstallationScript -eq "y") {
        if (($configFile.postInstallationScriptFolderPath).StartsWith("..")) {
            $global:postInstallationScriptFolderPath = "$scriptPath\configuration-files\$($configFile.postInstallationScriptFolderPath)"
            $global:postInstallationScriptName = $configFile.postInstallationScriptName
            $global:postConfigurationScriptName = $configFile.postConfigurationScriptName
        }
        else {
            $global:postInstallationScriptFolderPath = $configFile.postInstallationScriptFolderPath
            $global:postInstallationScriptName = $configFile.postInstallationScriptName
        }

        if (! (test-path $postInstallationScriptFolderPath)) {
            Write-Error "Post installation folder not found"
            Exit 0
        }
        if (! (test-path "$postInstallationScriptFolderPath\$postInstallationScriptName")) {
            Write-Error "Post installation script not found"
            Exit 0
        }
    }
    if ($isPostConfigurationScript -eq "y") {
        if (($configFile.postConfigurationScriptFolderPath).StartsWith("..")) {
            $global:postConfigurationScriptFolderPath = "$scriptPath\configuration-files\$($configFile.postConfigurationScriptFolderPath)"
            $global:postConfigurationScriptName = $configFile.postConfigurationScriptName
        }
        else {
            $global:postConfigurationScriptFolderPath = $configFile.postConfigurationScriptFolderPath
            $global:postConfigurationScriptName = $configFile.postConfigurationScriptName
        }

        if (! (test-path $postConfigurationScriptFolderPath)) {
            Write-Error "Post configuration folder not found"
            Exit 0
        }

        if (! (test-path "$postInstallationScriptFolderPath\$postConfigurationScriptName")) {
            Write-Error "Post configuration script not found"
            Exit 0
        }
    }

    Write-Host
    Write-Host "Provide the absolute path of the disk file: " -ForegroundColor Yellow -NoNewline
    $global:diskFilePath = Read-Host

    if (! (test-path $diskFilePath)) {
        Write-Error "Disk file not found"
        Exit 0
    }
}

function Get-ServerInformation {
    # Submitted server information
    Write-Host "============================"
    Write-Host "SUBMITTED SERVER INFORMATION"
    Write-Host "============================"
    Write-Host "Servername: $vmName"
    Write-Host "OS type: $osType"
    Write-Host "RAM size (in MB): $memSizeMb"
    Write-Host "vRAM size (in MB): $vramMb"
    Write-Host "Numver of CPUs: $nofCPUs"
    Write-Host "Full name: $fullUserName"
    Write-Host "Username: $username"
    Write-Host "Password: $password"
    Write-Host "Disk file: $diskFilePath"
    if ($isPostInstallationScript -eq "y") {
        Write-Host "Post installation folder: $postInstallationScriptFolderPath"
        Write-Host "Post installation script: $postInstallationScriptName"
    }
    if ($isPostConfigurationScript -eq "y") {
        Write-Host "Post configuration folder: $postConfigurationScriptFolderPath"
        Write-Host "Post configuration script: $postConfigurationScriptName"
    }    
}

function New-VM {
    Write-Host "========="
    Write-Host "CREATE VM"
    Write-Host "========="
    $vmPath="C:\Users\$($env:UserName)\VirtualBox VMs\$vmName"

    # Create the VM
    Write-Host Creating VM ...
    VBoxManage createvm --name $vmName --ostype $osType --register
    if (! (test-path $vmPath\$vmName.vbox)) {
      Write-Host "I expected a .vbox"
      Exit 0
    }

    # Add SATA controller and attach hard disk to it
    VBoxManage storagectl    $vmName --name       'SATA Controller' --add sata --controller IntelAhci
    VBoxManage storageattach $vmName --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium  $diskFilePath

    # Enable APIC
    VBoxManage modifyvm $vmName --ioapic on

    # Specify boot order of devices
    VBoxManage modifyvm $vmName --boot1 dvd --boot2 disk --boot3 none --boot4 none

    # Memory
    VBoxManage modifyvm $vmName --memory $memSizeMb --vram $vramMb

    # Number of CPUs
    VBoxManage modifyvm $vmName --cpus $nofCPUs

    # Set network adapter 
    VBoxManage modifyvm $vmName --nic1 nat
    VBoxManage modifyvm $vmName --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"

    # Enable clipboard content sharing
    VBoxManage modifyvm $vmName --clipboard-mode bidirectional

    # Set VBoxSVGA
    VBoxManage modifyvm $vmName --graphicscontroller vboxsvga
}

function Configure-VM {
    Write-Host "==============="
    Write-Host "CONFIGURE VM"
    Write-Host "==============="

    # Start the virtual machine
    Write-Host "Starting VM ..."
    VBoxManage startvm $vmName

    # Wait until installation is finished
    Write-Host "Waiting until VM is installed..."
    #VBoxManage guestproperty wait $vmName installation_finished

    Write-Host "Waiting until VM is ready..."
    $output=""
    do {
        sleep 10
        $output=$(VBoxManage guestcontrol $vmName run --exe "echo hello world" --username $userName --password $password 2>$null)
        Write-Host "Waiting until VM is ready..."
    } until ($output -match "Hello World")
    
    if ($isPostInstallationScript -eq "y") {
        # Set execution policy to unrestricted
        Write-Host "Setting execution policy to unrestricted..."
        VBoxManage guestcontrol $vmName run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username $userName --password $password -- "Set-ExecutionPolicy Unrestricted -Scope CurrentUser"

        # Copy post installation script
        Write-Host "Copying post installation script..."
        # Get the name of the post installation folder
        $postInstallFolderName = $postInstallationScriptFolderPath.Substring($postInstallationScriptFolderPath.LastIndexOf("\")+1,$postInstallationScriptFolderPath.Length-$postInstallationScriptFolderPath.LastIndexOf("\")-1)
        VBoxManage guestcontrol $vmName copyto $postInstallationScriptFolderPath "/postinstallation" --username $userName --password $password

        # Run post installation script
        Write-Host "Running post installation script..."
        VBoxManage guestcontrol $vmName run "/postinstallation/$postConfigurationScriptName" --username $userName --password $password
        
        # Restart VM
        Write-Host "Waiting until VM is ready..."
        $guestservice=""
        do {
            sleep 15
            $guestservice=$(VBoxManage guestcontrol $vmName run --exe "echo hello world" --username $userName --password $password 2>$null)
        } until ($guestservice -match "Hello World")
    }

    if ($isPostConfigurationScript -eq "y") {
        # Run post configuration script
        Write-Host "Running post configuration script..."
        Write-Host
        sleep 90
        VBoxManage guestcontrol $vmName run "/postinstallation/$postConfigurationScriptName" --username $userName --password $password
    }

    Write-Host VM installed
}

# Main function
function Main {
    do {
        Get-ConfigServerInformation
        Write-Host
        Get-ServerInformation
        Write-Host "Do you agree with the above details? (y/n): " -ForegroundColor Yellow -NoNewline
        $serverInformationAgree = Read-Host
        if ($serverInformationAgree -match "y") {
            Write-Host
        }
        elseif ($serverInformationAgree -match "n") {
            Clear-Host
        }
    } until ($serverInformationAgree -match "y")
    New-VM
    Write-Host
    Configure-VM
}

Main