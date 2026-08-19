#!/bin/bash
cd "$(dirname "$0")" || exit

### START CONTAINERS ###

docker compose -f compose.yml up --detach --build --pull=always