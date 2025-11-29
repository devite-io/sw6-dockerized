#!/bin/bash
cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <shopware container>"
  exit 1
fi

swContainer="$1"
swDir="/usr/share/nginx/html"

# update symfony flex recipes
cd ../shopware-dockerized/sw-symfony-flex
composer update --no-scripts
git stash && composer recipes:update --no-interaction shopware/administration && git stash pop
git stash && composer recipes:update --no-interaction shopware/core && git stash pop
git stash && composer recipes:update --no-interaction shopware/storefront && git stash pop
cd ../../

# update Shopware
docker cp ./shopware-dockerized/sw-symfony-flex/composer.json $swContainer:/usr/share/nginx/html/
docker exec $swContainer bash -c "cd /usr/share/nginx/html && chmod 0777 composer.json && chown nginx:nginx composer.json"
docker exec --user nginx $swContainer bash -c "cd /usr/share/nginx/html && composer update --no-scripts"

# copy back updated composer files
docker cp $swContainer:/usr/share/nginx/html/composer.json ./shopware-dockerized/sw-symfony-flex/composer.json
docker cp $swContainer:/usr/share/nginx/html/composer.lock ./shopware-dockerized/sw-symfony-flex/composer.lock