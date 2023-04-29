# csv-npe-2223

Cybersecurity &amp; Virtualisation - NPE Opdracht 2022-2023

# Deplayment manual

## 1. Installatie van de vm's

- Download volgende vdi-bestanden van osboxes.org:

  - [Kali Linux 2022.3](https://sourceforge.net/projects/osboxes/files/v/vb/25-Kl-l-x/2022.3/64bit.7z/download)
  - [Debian 11 - Desktop](https://sourceforge.net/projects/osboxes/files/v/vb/14-D-b/11/Workstation/64bit.7z/download)

- Unzip de vdi-bestanden rechtstreeks in de download folder de huidige gebruiker
- Hernoem de vdi-bestanden naar:

  - Kali Linux 2022.3.vdi => KaliVM.vdi
  - Debian 11 - Desktop.vdi => DebianVM.vdi

- Voer de volgende commando's uit in powerhshell van de host machine:

  ```powershell
  ./VM_Installation.ps
  ```

## 2. Installatie van de applicaties
