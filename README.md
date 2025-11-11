# Docker Laravel Multi-Site Setup

Ce projet configure deux sites Laravel identiques avec une base de données MySQL partagée en utilisant Docker.

## Structure

- **2 services Nginx** (ports 8001 et 8002)
- **2 services PHP-FPM** (avec Composer et Node.js)
- **1 base de données MySQL** (partagée entre les deux sites)

## Architecture

```
projet/
├── docker-compose.yml       # Configuration des services
├── Dockerfile              # Image PHP avec Composer et Node.js
├── entrypoint.sh           # Script d'automatisation Laravel
├── nginx-site1.conf        # Configuration Nginx pour site 1
├── nginx-site2.conf        # Configuration Nginx pour site 2
├── site-1/                 # Code source du site 1
│   ├── .env               # Configuration DB pour site 1
│   └── ...
└── site-2/                 # Code source du site 2
    ├── .env               # Configuration DB pour site 2
    └── ...
```

## Prérequis

- Docker Desktop installé
- Docker Compose installé
- Ports 8001, 8002 et 3307 disponibles (3306 est le port interne MySQL)

## Configuration

Les fichiers `.env` existent déjà pour les deux sites. Vérifiez que la section base de données contient bien :

```
DB_CONNECTION=mysql
DB_HOST=mysql_laravel
DB_PORT=3306
DB_DATABASE=laravel_db
DB_USERNAME=laravel_user
DB_PASSWORD=laravel_password
```

## Démarrage

1) Construire et démarrer les conteneurs

```powershell
docker-compose up -d --build
```

2) Mettre à jour les dépendances PHP (premier lancement uniquement)

Le lock file du projet cible PHP < 8.2. Avec l'image `php:8.2-fpm`, mettez à jour les dépendances dans chaque site :

```powershell
docker exec -it php_laravel_site1 composer update --no-interaction --optimize-autoloader
docker exec -it php_laravel_site2 composer update --no-interaction --optimize-autoloader
```

3) Installer les dépendances front et builder les assets

```powershell
docker exec -it php_laravel_site1 npm install
docker exec -it php_laravel_site1 npm run build

docker exec -it php_laravel_site2 npm install
docker exec -it php_laravel_site2 npm run build
```

4) Générer les clés applicatives

```powershell
docker exec -it php_laravel_site1 php artisan key:generate
docker exec -it php_laravel_site2 php artisan key:generate
```

5) Migrer et peupler la base (une seule fois)

```powershell
docker exec -it php_laravel_site1 php artisan migrate:fresh --seed --force
```

6) (Optionnel) Vérifier les logs et l’état

```powershell
docker-compose ps
docker-compose logs -f
```

Ensuite, accédez aux sites :

- Site 1 : http://localhost:8001
- Site 2 : http://localhost:8002

Créez un utilisateur sur chaque site pour constater que la base est partagée.

## Accès aux sites

- **Site 1** : http://localhost:8001
- **Site 2** : http://localhost:8002

## Fonctionnalités automatisées

Le script `entrypoint.sh` exécute automatiquement au démarrage :

1. `composer install` - Installation des dépendances PHP
2. `npm install` - Installation des dépendances Node.js
3. `npm run build` - Compilation des assets
4. `php artisan key:generate` - Génération de la clé d'application
5. `php artisan migrate:fresh --seed` - Migration et seed de la base de données (premier démarrage)

## Test de l'inscription/connexion

1. Accédez à http://localhost:8001
2. Cliquez sur "Register" pour créer un compte
3. Remplissez le formulaire et créez un utilisateur
4. Accédez à http://localhost:8002
5. Créez un deuxième utilisateur

## Vérification de la base de données

Pour vérifier que les deux utilisateurs sont bien dans la même base de données :

```powershell
# Accéder à la base de données
docker exec -it mysql_laravel mysql -ularavel_user -plaravel_password laravel_db

# Dans MySQL, exécuter :
SELECT * FROM users;

# ou dans le terminal VSC :
docker exec -it mysql_laravel mysql -ularavel_user -plaravel_password laravel_db -e "SELECT * FROM users;"
```
## Commandes utiles

```powershell
docker-compose down
```

```powershell
docker-compose down -v
```

### Reconstruire les images

```powershell
docker-compose build --no-cache
docker-compose up -d
```

### Accéder au shell d'un conteneur

```powershell
# PHP Site 1
docker exec -it php_laravel_site1 bash

# PHP Site 2
docker exec -it php_laravel_site2 bash

# MySQL
docker exec -it mysql_laravel bash
```

```powershell
# Site 1
docker exec -it php_laravel_site1 php artisan migrate
docker exec -it php_laravel_site1 php artisan tinker

# Site 2
docker exec -it php_laravel_site2 php artisan migrate
docker exec -it php_laravel_site2 php artisan tinker
```

## Troubleshooting

### Les assets ne se chargent pas

Si les assets (CSS/JS) ne se chargent pas correctement :

```powershell
docker exec -it php_laravel_site1 npm run build
docker exec -it php_laravel_site2 npm run build
```

### Erreur de connexion à la base de données

Vérifiez que MySQL est bien démarré :

```powershell
docker-compose logs mysql_laravel
```

### Permissions

Si vous rencontrez des problèmes de permissions :

```powershell
docker exec -it php_laravel_site1 chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
docker exec -it php_laravel_site2 chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
```

## Différences entre les sites

Les deux sites sont identiques sauf :

- **Site 1** affiche "Serveur 1" sur la page d'accueil
- **Site 2** affiche "Serveur 2" sur la page d'accueil

Les deux sites partagent la même base de données MySQL.
