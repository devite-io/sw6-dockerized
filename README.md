# Shopware 6 dockerized

This is a production-ready dockerized setup for Shopware 6.

## Installing Shopware

```bash
bash deploy.sh && bash ./bin/install-shopware.sh . en_GB EUR
```

## Starting server

```bash
bash deploy.sh
```

## Stopping server

```bash
docker compose down
```

## Updating Symfony project

Set the targeted version in the `./shopware-dockerized/sw-symfony-flex/composer.json`, then run:

```bash
bash ./bin/update-sw-symfony-flex.sh .
cd ./shopware-dockerized/sw-symfony-flex
composer recipes:update --no-interaction shopware/administration
composer recipes:update --no-interaction shopware/core
composer recipes:update --no-interaction shopware/elasticsearch
composer recipes:update --no-interaction shopware/storefront
cd ../../
```