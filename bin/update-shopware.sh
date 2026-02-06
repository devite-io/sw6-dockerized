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

# delete indices that might cause conflicts
docker exec --user nginx $swContainer curl -X DELETE 'http://opensearch:9200/sw_product'
docker exec --user nginx $swContainer bash -c "cd $swDir && bin/console es:reset --no-interaction"
docker exec --user nginx $swContainer bash -c "cd $swDir && bin/console es:admin:reset --no-interaction"
docker exec --user nginx $swContainer bash -c "cd $swDir && bin/console cache:clear:all"

# update Shopware
docker cp ./shopware-dockerized/sw-symfony-flex/composer.json $swContainer:$swDir/
docker exec $swContainer bash -c "cd $swDir && chmod 0777 composer.json && chown nginx:nginx composer.json"
docker exec --user nginx $swContainer bash -c "cd $swDir && composer update --no-scripts"

# copy back updated composer files
docker cp $swContainer:$swDir/composer.json ./shopware-dockerized/sw-symfony-flex/composer.json
docker cp $swContainer:$swDir/composer.lock ./shopware-dockerized/sw-symfony-flex/composer.lock