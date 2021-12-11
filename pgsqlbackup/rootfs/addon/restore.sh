#!/usr/bin/with-contenv bashio

set -e

source /addon/.backupenv

RESTORE_EXTRA_OPTS=""
for i in "$@"; do
  case $i in
    -e=*|--extraargs=*)
      RESTORE_EXTRA_OPTS="${i#*=}"
      shift # past argument=value
      ;;
    -i=*|--input=*)
      FILENAME="${i#*=}"
      shift # past argument=value
      ;;
  esac
done

if [ -z "$FILENAME" ]; then
    bashio::exit.nok "input file is not defined !"
    exit 1
fi

BACKUPINPUT="${BACKUP_DIR}/$FILENAME"

if [ ! -f "$BACKUPINPUT" ]; then
    bashio::exit.nok "backup file does not exist !"
    exit 1
fi

bashio::log.info "Restoration starting for ${POSTGRES_DB}"

if [ "${POSTGRES_DB}" = "**None**" ]; then
  bashio::exit.nok "You need to set the database."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=${POSTGRES_PORT_5432_TCP_ADDR}
    POSTGRES_PORT=${POSTGRES_PORT_5432_TCP_PORT}
  else
    bashio::exit.nok "You need to set the postgresql host"
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  bashio::exit.nok "You need to set the psotgresql user."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  bashio::exit.nok "You need to set the postgresql password."
  exit 1
fi

POSTGRES_DBS=$(echo "${POSTGRES_DB}" | tr , " ")

export PGUSER="${POSTGRES_USER}"
export PGPASSWORD="${POSTGRES_PASSWORD}"
export PGHOST="${POSTGRES_HOST}"
export PGPORT="${POSTGRES_PORT}"

#Loop all databases
for DB in ${POSTGRES_DBS}; do

  #Create dump
  if [ "${POSTGRES_CLUSTER}" = "true" ]; then
    bashio::log.info "Restoring dump into ${DB} (cluster mode) to ${POSTGRES_HOST} from ${DFILE}..."
    gunzip -c "${FILENAME}" | psql "${DB}"
  else
    bashio::log.info "Restoring dump into ${DB} to ${POSTGRES_HOST} from ${DFILE}..."
    pg_restore -d "${DB}" -f "${FILENAME}" ${RESTORE_EXTRA_OPTS}
  fi
  
done

bashio::exit.ok "SQL restored successfully"