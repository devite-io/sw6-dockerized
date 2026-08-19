#!/bin/bash
scriptDir="$(realpath "$(dirname "$0")")"

if [ $# -ne 3 ]; then
  echo "Usage: $0 <compose project path> <locale> <currency>"
  exit 1
fi

composeProjectPath="$(realpath "$1")"
locale="$2"
currency="$3"
swDir="/usr/share/nginx/html"

cd "$composeProjectPath"

# install dependencies
docker compose exec --user nginx shopware bash -c "cd $swDir && composer install --no-dev"

# install Shopware
docker compose exec --user nginx shopware bash -c "cd $swDir && bin/console system:install --create-database --basic-setup --shop-locale='$locale' --shop-currency='$currency' --force"
docker compose restart shopware

# apply patches
bash "$scriptDir/apply-patches.sh" "$composeProjectPath"

# run post-install scripts
for script in "$scriptDir/post-install.d/"*.sh; do
  if [ -x "$script" ]; then
    echo "Running post-install script: $script"
    "$script" "$composeProjectPath"
  fi
done