#!/bin/bash
scriptDir="$(realpath "$(dirname "$0")")"

if [ $# -ne 4 ]; then
  echo "Usage: $0 <compose project path> <db password> <locale> <currency>"
  exit 1
fi


### BEGIN VALIDATION ###

composeProjectPath="$(realpath "$1")"
dbPassword="$2"
locale="$3"
currency="$4"


### BEGIN SELF-UPDATE ###

cd "$scriptDir/.." && git pull


### BEGIN DATA MIGRATION ###

# backup Shopware installation
bash "$scriptDir/backup.sh" "$composeProjectPath" "$dbPassword"

# run pre-update scripts
for script in "$scriptDir/pre-update.d/"*.sh; do
  if [ -x "$script" ]; then
    echo "Running pre-update script: $script"
    "$script" "$composeProjectPath" "$dbPassword" "$locale" "$currency"
  fi
done

# update composer.json
cd "$composeProjectPath"

version=$(jq -r '.require["shopware/core"]' "$scriptDir/../shopware-dockerized/sw-symfony-flex/composer.json")
docker compose exec --user nginx shopware sed -i -E "s/(\"shopware\/core\":\s*\")([^\"]+)(\")/\1$version\3/" composer.json
docker compose exec --user nginx shopware sed -i -E "s/(\"shopware\/administration\":\s*\")([^\"]+)(\")/\1$version\3/" composer.json
docker compose exec --user nginx shopware sed -i -E "s/(\"shopware\/elasticsearch\":\s*\")([^\"]+)(\")/\1$version\3/" composer.json
docker compose exec --user nginx shopware sed -i -E "s/(\"shopware\/storefront\":\s*\")([^\"]+)(\")/\1$version\3/" composer.json

# perform update
docker compose exec --user nginx shopware bash -c "cd /usr/share/nginx/html && bin/console system:update:prepare && composer update --no-scripts && bin/console system:update:finish"


### BEGIN CONTAINER UPDATE ###

bash "$scriptDir/backup.sh" "$composeProjectPath" "$dbPassword" --no-bundles

# delete containers and their data, then recreate them
docker compose down -v
bash "$composeProjectPath/deploy.sh"

# reinstall Shopware
bash "$scriptDir/install-shopware.sh" "$composeProjectPath" "$locale" "$currency"

# restore container data
mostRecentBackupFile=$(ls -t "$composeProjectPath/backups"/*.tar.gz 2>/dev/null | head -n 1)

if [[ -n "$mostRecentBackupFile" ]]; then
  bash "$scriptDir/restore-backup.sh" "$composeProjectPath" "$dbPassword" "$mostRecentBackupFile"
  rm "$mostRecentBackupFile"
else
  echo "Could not restore data after container update."
  exit 1
fi

# run post-update scripts
for script in "$scriptDir/post-update.d/"*.sh; do
  if [ -x "$script" ]; then
    echo "Running post-update script: $script"
    "$script" "$composeProjectPath" "$dbPassword" "$locale" "$currency"
  fi
done