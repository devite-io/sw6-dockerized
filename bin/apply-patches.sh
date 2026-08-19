#!/bin/bash
scriptDir="$(realpath "$(dirname "$0")")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <compose project path>"
  exit 1
fi

composeProjectPath="$(realpath "$1")"
swDir="/usr/share/nginx/html"

cd "$composeProjectPath"

docker compose cp "$scriptDir/../patches/." shopware:$swDir/vendor/shopware/
docker compose exec shopware bash -c "cd $swDir/vendor/shopware && chown -R nginx:nginx . && chmod -R 0777 ."

# rebuild Administration
docker compose exec shopware bash -c "apt install -y jq"
docker compose exec --user nginx shopware bash -c "cd $swDir && bash bin/build-administration.sh 2>&1 > /dev/null"
docker compose restart shopware