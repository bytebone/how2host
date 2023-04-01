#! /bin/bash

## == Config Section ==

# Amount of backups to keep
# After a service update, all backups but the latest one of the old version are deleted.
keepFiles=14
# Where to store the backups
# make sure this is an absolute path!
storage="/media/backups/vault"

## == Config End ==

ver=$(docker container inspect vaultwarden-app | grep "opencontainers.image.version" | cut -d\" -f4)

if [[ ! -e "${storage}" ]]; then mkdir -p ${storage}; fi
cd ${storage}
if [[ ! -e "${ver}" ]]
then
  ls $(ls -r | head -n 1)/* | head -n-1 | xargs rm
  mkdir $ver
fi
cd $ver

docker exec vaultwarden-db pg_dumpall -c -U vault | gzip > ${ver//./-}_$(date "+%y%m%d_%H%M%S")_vw-db.gz
if [[ "$(ls *.gz | wc -l)" -gt $keepFiles ]]; then
	ls -t | sed -e "1, ${keepFiles}d" | xargs -d '\n' rm
fi
