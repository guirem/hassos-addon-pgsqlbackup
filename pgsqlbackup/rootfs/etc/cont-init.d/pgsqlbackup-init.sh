#!/usr/bin/with-contenv bashio

source /addon/.backupenv


# Create /share/tautulli if it does not exist.
if ! bashio::fs.directory_exists "$BACKUP_DIR"; then
    mkdir "$BACKUP_DIR"
fi


# setup cron schedule
if [ "${BACKUP_SCHEDULE_ENABLED}" = "true" ]; then
    bashio::log.green " Using '$BACKUP_SCHEDULE' as schedule"
    echo "$BACKUP_SCHEDULE   /addon/backup.sh" > /etc/crontabs/root
    bashio::log.green " Cron schedule is ready"
else
    bashio::log.blue " Schedule is disabled"
fi

bashio::log.green " Add-on initiated"

