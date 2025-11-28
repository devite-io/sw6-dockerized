#!/bin/bash
cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <shopware container>"
  exit 1
fi

swContainer="$1"
swDir="/usr/share/nginx/html"

docker cp ../patches/. $swContainer:$swDir/vendor/shopware/
docker exec $swContainer bash -c "cd $swDir/vendor/shopware && chown -R nginx:nginx . && chmod -R 0777 ."

# rebuild Administration
docker exec $swContainer bash -c "apt install -y jq"
docker exec --user nginx $swContainer bash -c "cd $swDir && bash bin/build-administration.sh 2>&1 > /dev/null"
docker container restart $swContainer