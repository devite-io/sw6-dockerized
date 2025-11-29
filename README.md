# Shopware 6 dockerized

This is a production-ready dockerized setup for Shopware 6.

## Starting server

```bash
docker compose up -d
```

## Stopping server

```bash
docker compose down
```

## Installing Shopware

```bash
bash ./bin/install-shopware.sh sw6-shopware-1
```

## Updating Shopware

Set the targeted version in the `./shopware-dockerized/sw-symfony-flex/composer.json`, then run:

```bash
bash ./bin/update-shopware.sh sw6-shopware-1
```