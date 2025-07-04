# Documentation de déploiement automatique WordPress avec Ansible et Docker

## 📌 Objectif

Ce projet automatise le déploiement complet de WordPress avec Apache, PHP et MariaDB sur deux conteneurs Docker distincts (Ubuntu et Rocky Linux), en utilisant Ansible comme outil d'orchestration.

## 🧱 Arborescence du projet

```bash
.
├── Install_wordpress.sh                  # Script initial de référence (non utilisé dans Ansible)
├── Makefile                              # Cibles Make pour build / clean / deploy
├── README.md                             # Ce fichier de documentation
├── docker-compose.yml                    # Définition des conteneurs Ubuntu et Rocky
├── inventory.yml                         # Fichier d'inventaire Ansible
├── logs
│   └── deploy.log                        # Log détaillé du déploiement
├── roles
│   └── wordpress_install                 # Rôle Ansible principal
│       ├── defaults
│       │   └── main.yml                  # Valeurs par défaut (ex: ports, users)
│       ├── handlers
│       │   └── main.yml                  # Reload Apache
│       ├── tasks                         # Découpe logique des étapes
│       │   ├── apache_config.yml         # Configuration Apache + vhost
│       │   ├── install_packages.yml      # Installation de Apache, PHP, MariaDB, etc.
│       │   ├── main.yml                  # Inclusion des sous-tâches
│       │   ├── mysql_config.yml          # Création DB, user, sécurisation
│       │   ├── mysql_repair_root.yml     # Réinitialisation mot de passe root si besoin
│       │   └── wordpress_setup.yml       # Téléchargement, permissions et config WP
│       ├── templates
│       │   ├── wordpress.conf.j2         # Template du virtualhost Apache
│       │   └── wp-config.php.j2          # Fichier de config WordPress
│       └── vars
│           └── main.yml                  # Variables sensibles ou de surcharges
└── site.yml                              # Playbook principal
```

## ⚙️ Fonctionnement global

Ce projet repose sur trois composants principaux :

1. **Docker Compose** : Crée deux conteneurs distincts (Ubuntu et Rocky) accessibles via les ports 2222 (Ubuntu) et 2223 (Rocky) pour SSH, et 8080/8081 pour Apache.
2. **Makefile** : Facilite les commandes usuelles : démarrage, nettoyage, déploiement.
3. **Ansible** : Configure automatiquement Apache, MariaDB et WordPress dans chaque conteneur.

## 🔐 Sécurité de la connexion SSH

Une paire de clés SSH est générée automatiquement. La clé publique est injectée dans chaque conteneur, dans le répertoire `/home/ansible/.ssh/authorized_keys`. Cela permet à Ansible de s’y connecter sans mot de passe.

## 🚀 Étapes d'utilisation

### 1. Lancer les conteneurs et injecter les clés SSH

```bash
make
```

Cette commande :

* Lance les conteneurs avec Docker Compose
* Génère une paire de clés SSH si elle n’existe pas
* Injecte la clé publique dans les conteneurs Ubuntu et Rocky

### 2. Vérifier la connectivité Ansible

```bash
ansible -i inventory.yml all -m ping
```

Les deux hôtes doivent répondre avec `pong`.

### 3. Déployer WordPress

```bash
make deploy
```

Le playbook `site.yml` est exécuté. Les logs détaillés sont sauvegardés dans :

```bash
logs/deploy.log
```

### 4. Vérifier l’installation

* Ouvrir [http://localhost:8080](http://localhost:8080) pour Ubuntu
* Ouvrir [http://localhost:8081](http://localhost:8081) pour Rocky

Vous devriez voir l’assistant de configuration WordPress (choix de langue).

Si la page par défaut d’Apache s’affiche encore, relancez `make deploy` pour appliquer les bonnes permissions et la suppression des fichiers par défaut.

## 🧩 Variables personnalisables

Définies dans `roles/wordpress_install/vars/main.yml` :

```yaml
wordpress_db_name: wordpress
wordpress_db_user: example
wordpress_db_password: examplePW
mysql_root_password: examplerootPW
wordpress_web_dir: /var/www/html
```

## 🧩 Explication détaillée du rôle `wordpress_install`

Ce rôle est découpé en plusieurs fichiers pour plus de lisibilité et de réutilisabilité :

### `install_packages.yml`

Installe les paquets nécessaires pour chaque distribution. Les modules conditionnels (`apt` ou `dnf`) sont utilisés en fonction de la famille de l’OS.

### `mysql_config.yml`

* Sécurisation de MariaDB (suppression des utilisateurs anonymes et de la base `test`)
* Définition du mot de passe root
* Création de la base `wordpress`
* Création de l’utilisateur `example`
* Attribution des droits nécessaires
* Détection automatique du bon socket (`/var/run/mysqld/mysqld.sock` ou `/var/lib/mysql/mysql.sock`)

### `wordpress_setup.yml`

* Téléchargement de WordPress depuis `wordpress.org`
* Décompression dans le répertoire défini (`wordpress_web_dir`)
* Création du fichier `wp-config.php` depuis un template Jinja2 dynamique
* Application des bons droits sur les fichiers pour `www-data` (Debian) ou `apache` (RedHat)
* Nettoyage de la page par défaut Apache

### `apache_config.yml`

* Déploiement du fichier virtualhost depuis un template (`wordpress.conf.j2`)
* Activation du site et du module `rewrite` sur Debian
* Configuration manuelle du `ServerName` sur Rocky
* Gestion conditionnelle du redémarrage Apache :

  * `service apache2 reload` sur Debian
  * message informatif sur Rocky (Apache tourne en arrière-plan dans le conteneur, pas de reload possible)

### `handlers/main.yml`

Déclenche le redémarrage du service Apache si un fichier de configuration est modifié (template ou copy).

## 🧹 Nettoyage complet

```bash
make clean
```

Cela :

* Supprime les conteneurs
* Efface la paire de clés SSH
* Supprime les fichiers de log

## ✅ Tests attendus après déploiement

* Connexion SSH fonctionnelle avec Ansible
* `ansible all -m ping` renvoie `pong`
* Accès à [http://localhost:8080](http://localhost:8080) et [http://localhost:8081](http://localhost:8081)
* Affichage de l’interface d’installation WordPress (choix de langue)

## 👨‍🎓 Auteur

**Ahmed-Khalil DJOGHLAL** — Évaluation DevOps : Déploiement automatisé d'applications Web avec Ansible et Docker.

---

🧠 *Ce projet est un exemple complet d'infrastructure as code (IaC), prêt à être déployé sur tout environnement supportant Docker et Ansible.*
