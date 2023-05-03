$env:PATH = $env:PATH + ";C:\Program Files\Oracle\VirtualBox"

#create DrupalVM
VBoxManage createvm --name "DrupalVM" --ostype Debian_64 --register

#add storage controller
VBoxManage storagectl "DrupalVM" --name "SATA Controller" --add sata --controller IntelAHCI

# vdi file path
$VDI = "C:\ISO files\64bit\Debian 11 (64bit).vdi"

# add vdi file to vm
VBoxManage storageattach "DrupalVM" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VDI

# add cd drive to vm
VBoxManage storageattach "DrupalVM" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium emptydrive



# VM name
$VM = "DrupalVM"

#add network adapter
VBoxManage modifyvm $VM --nic1 nat 

# add hostonly network adapter
VBoxManage modifyvm $VM --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter #2"


#change ram to 2gb 2 cpu and 128mb video memory
VBoxManage modifyvm $VM --memory 2048 --cpus 2 --vram 128

#start vm
VBoxManage startvm $VM
