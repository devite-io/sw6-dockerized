#!/bin/sh

# run all scripts in /docker-entrypoint.d, sort by filename
for f in /docker-entrypoint.d/*.sh; do
  if [ -f "$f" ]; then
    echo "Running $f"
    . "$f"
  fi
done

# delete all caches and logs to avoid permission issues
rm -rf /usr/share/nginx/html/var/cache/*
rm -rf /usr/share/nginx/html/var/log/*
rm -f /var/log/run-scheduled-task.log

# start supervisor
echo "Starting Supervisor"
rm -f /var/log/supervisord.log
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf