#!/bin/bash
scriptDir="$(realpath "$(dirname "$0")")"

if [ $# -ne 6 ]; then
  echo "Usage: $0 <source compose project path> <staging compose project path> <source db password> <staging db password> <locale> <currency>"
  exit 1
fi


### BEGIN VALIDATION ###

sourceComposeProjectPath="$(realpath "$1")"
stagingComposeProjectPath="$(realpath "$2")"
sourceDbPassword="$3"
stagingDbPassword="$4"
locale="$5"
currency="$6"


### BEGIN CONTAINER DATA IMPORT ###

# backup source container data
bash "$scriptDir/backup.sh" "$sourceComposeProjectPath" "$sourceDbPassword" --no-bundles

# delete existing staging container data
cd "$stagingComposeProjectPath"
docker compose down -v

# install Shopware in staging environment
bash "$stagingComposeProjectPath/deploy.sh"
bash "$scriptDir/install-shopware.sh" "$stagingComposeProjectPath" "$locale" "$currency"

mostRecentBackupFile=$(ls -t "$sourceComposeProjectPath/backups"/*.tar.gz 2>/dev/null | head -n 1)

if [[ -n "$mostRecentBackupFile" ]]; then
  bash "$scriptDir/restore-backup.sh" "$stagingComposeProjectPath" "$stagingDbPassword" "$mostRecentBackupFile"
  rm "$mostRecentBackupFile"
else
  echo "Could not create staging environment from production environment."
  exit 1
fi

# run staging-migration scripts
for script in "$scriptDir/staging-migration.d/"*.sh; do
  if [ -x "$script" ]; then
    echo "Running staging-migration script: $script"
    "$script" "$stagingComposeProjectPath" "$stagingDbPassword" "$locale" "$currency"
  fi
done