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