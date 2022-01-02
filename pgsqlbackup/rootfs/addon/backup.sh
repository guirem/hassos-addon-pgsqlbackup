#!/usr/bin/with-contenv bashio

set -e

source /addon/.backupenv

OVERWRITTEN_FILENAME=""

for i in "$@"; do
  case $i in
    -e=*|--extraargs=*)
      POSTGRES_EXTRA_OPTS="${i#*=}"
      shift # past argument=value
      ;;
    -o=*|--output=*)
      OVERWRITTEN_FILENAME="${i#*=}"
      shift # past argument=value
      ;;
  esac
done

bashio::log.info "Backup starting for ${POSTGRES_DB}"

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

KEEP_DAYS=${BACKUP_KEEP_DAYS}
KEEP_WEEKS=`expr $(((${BACKUP_KEEP_WEEKS} * 7) + 1))`
KEEP_MONTHS=`expr $(((${BACKUP_KEEP_MONTHS} * 31) + 1))`

#Initialize dirs
mkdir -p "${BACKUP_DIR}/daily/" "${BACKUP_DIR}/weekly/" "${BACKUP_DIR}/monthly/"

#Loop all databases
for DB in ${POSTGRES_DBS}; do
  #Initialize filename vers
  if [ -z $OVERWRITTEN_FILENAME ]; then # only if filname not overwritten
    DFILE="${BACKUP_DIR}/daily/${DB}-`date +%Y%m%d-%H%M%S`${BACKUP_SUFFIX}"
    WFILE="${BACKUP_DIR}/weekly/${DB}-`date +%G%V`${BACKUP_SUFFIX}"
    MFILE="${BACKUP_DIR}/monthly/${DB}-`date +%Y%m`${BACKUP_SUFFIX}"
  else
    DFILE=${BACKUP_DIR}/$OVERWRITTEN_FILENAME
  fi
  #Create dump
  if [ "${POSTGRES_CLUSTER}" = "true" ]; then
    bashio::log.info "Creating cluster dump of ${DB} database from ${POSTGRES_HOST} into ${DFILE}..."
    pg_dumpall -l "${DB}" ${POSTGRES_EXTRA_OPTS} | gzip > "${DFILE}"
  else
    bashio::log.info "Creating dump of ${DB} database from ${POSTGRES_HOST} into ${DFILE}..."
    pg_dump -d "${DB}" -f "${DFILE}" ${POSTGRES_EXTRA_OPTS}
  fi

  if [ -z $OVERWRITTEN_FILENAME ]; then # only if filname not overwritten
    #Copy (hardlink) for each entry
    if [ -d "${DFILE}" ]; then
      WFILENEW="${WFILE}-new"
      MFILENEW="${MFILE}-new"
      rm -rf "${WFILENEW}" "${MFILENEW}"
      mkdir "${WFILENEW}" "${MFILENEW}"
      ln -f "${DFILE}/"* "${WFILENEW}/"
      ln -f "${DFILE}/"* "${MFILENEW}/"
      rm -rf "${WFILE}" "${MFILE}"
      mv -v "${WFILENEW}" "${WFILE}"
      mv -v "${MFILENEW}" "${MFILE}"
    else
      ln -vf "${DFILE}" "${WFILE}"
      ln -vf "${DFILE}" "${MFILE}"
    fi
    #Clean old files
    bashio::log.info "Cleaning older than ${KEEP_DAYS} days for ${DB} database from ${POSTGRES_HOST}..."
    find "${BACKUP_DIR}/daily" -maxdepth 1 -mtime +${KEEP_DAYS} -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rf '{}' ';'
    find "${BACKUP_DIR}/weekly" -maxdepth 1 -mtime +${KEEP_WEEKS} -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rf '{}' ';'
    find "${BACKUP_DIR}/monthly" -maxdepth 1 -mtime +${KEEP_MONTHS} -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rf '{}' ';'
  fi

done

bashio::exit.ok "SQL backup created successfully"