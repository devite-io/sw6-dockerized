#!/bin/bash
scriptDir="$(realpath "$(dirname "$0")")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <compose project path>"
  exit 1
fi

composeProjectPath="$(realpath "$1")"
swDir="/usr/share/nginx/html"

cd "$composeProjectPath"

documentsDir="/usr/share/nginx/html/vendor/shopware/core/Framework/Resources/views/documents"

docker compose exec shopware bash -c "rm -rf $documentsDir/*"
docker compose cp "$scriptDir/../document-templates/." shopware:$documentsDir/
docker compose exec shopware bash -c "cd $documentsDir && chown -R nginx:nginx . && chmod -R 0777 ."
docker compose restart shopware