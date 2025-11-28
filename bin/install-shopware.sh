#!/bin/bash
cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <shopware container>"
  exit 1
fi

swContainer="$1"
swDir="/usr/share/nginx/html"

# install dependencies
docker exec --user nginx $swContainer bash -c "cd $swDir && composer install --no-dev"

# install Shopware
docker exec --user nginx $swContainer bash -c "cd $swDir && bin/console system:install --create-database --basic-setup --shop-locale='de_DE' --force"
docker container restart $swContainer

# apply patches
bash ./apply-patches.sh $swContainer