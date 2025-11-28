#!/bin/sh

# run all scripts in /docker-entrypoint.d, sort by filename
for f in /docker-entrypoint.d/*.sh; do
  if [ -f "$f" ]; then
    echo "Running $f"
    . "$f"
  fi
done

# start supervisor
echo "Starting Supervisor"
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf