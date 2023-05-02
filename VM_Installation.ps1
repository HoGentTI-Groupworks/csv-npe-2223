Clear-Host

# Add Virtual Box bin-path to PATH environment variable if necessary
if ($null -eq (get-command VBoxManage.exe -errorAction silentlyContinue)) {
    $env:path="C:\Program Files\Oracle\VirtualBox;$env:path"
}
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

function New-VM([string] $vmName, [string] $osType, [int] $memSizeMb, [int] $nofCPUs, [string] $gpc, [int] $vramMb, [string] $vdiName) {
    # Variables
    $vmPath="C:\Users\$($env:UserName)\VirtualBox VMs\$vmName"
    $vdiPath = "C:\Users\$($env:UserName)\Downloads\$vdiName"

    # Start creating the VM
    Write-Host "=============="
    Write-Host "CREATE $($vmName.ToUpper())"
    Write-Host "=============="

    # Create the VM
    VBoxManage createvm --name $vmName --ostype $osType --register
    if (! (test-path $vmPath\$vmName.vbox)) {
      Write-Host "I expected a .vbox"
      Exit 0
    }

    # Add SATA controller and attach hard disk to it
    VBoxManage storagectl    $vmName --name       'SATA Controller' --add sata --controller IntelAhci
    VBoxManage storageattach $vmName --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium  $vdiPath

    VBoxManage createvm --name $vmName --ostype $osType --register
    if (! (test-path $vdiPath\$vmName.vdi)) {
      Write-Host "I expected a .vdi"
      Exit 0
    }

    # Add IDE controller and attach DVD drive to it
    VBoxManage storagectl    $vmName --name       'IDE Controller' --add ide
    VBoxManage storageattach $vmName --storagectl 'IDE Controller' --port 0 --device 0 --type dvddrive --medium emptydrive

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
    VBoxManage modifyvm $vmName --graphicscontroller $gpc

    # Start the virtual machine
    VBoxManage startvm $vmName
}

function New-DebianVm {
    # Variables
    $vmName = "DebianVM"
    $osType = "Debian_64"
    $memSizeMb = 4096
    $nofCPUs = 2
    $gpc = "vboxsvga"
    $vramMb = 128
    $vdiName = "Debian 11 (64bit).vdi"

    # Create the VM
    New-VM -vmName $vmName -osType $osType -memSizeMb $memSizeMb -nofCPUs $nofCPUs -gpc $gpc -vramMb $vramMb -vdiName $vdiName
}

function New-KaliVM {
    # Variables
    $vmName = "KaliVM"
    $osType = "Linux_64"
    $memSizeMb = 4096
    $nofCPUs = 2
    $gpc = "vboxsvga"
    $vramMb = 128
    $vdiName = "Kali Linux 2022.3 (64bit).vdi"

    # Create the VM
    New-VM -vmName $vmName -osType $osType -memSizeMb $memSizeMb -nofCPUs $nofCPUs -gpc $gpc -vramMb $vramMb -vdiName $vdiName
}

function Main {
    New-DebianVm
    New-KaliVM
}

Main