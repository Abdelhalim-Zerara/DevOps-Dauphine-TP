# Utiliser l'image officielle de WordPress comme base
FROM wordpress:latest

# Définir les variables d'environnement pour la base de données
ENV WORDPRESS_DB_USER=wordpress \
    WORDPRESS_DB_PASSWORD=ilovedevops \
    WORDPRESS_DB_NAME=wordpress \
    WORDPRESS_DB_HOST=35.224.51.182