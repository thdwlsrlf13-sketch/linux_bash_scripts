#!/bin/bash

BACKUP="/mnt/server2"
DATE=$(date +%F_%H-%M-%S)
MAX_RETRIES=6
RETRY_INTERVAL=10
NFS_READY=0

for ((i=1; i<=MAX_RETRIES; i++)); do

	/usr/bin/ls "$BACKUP" > /dev/null 2>&1

	if /usr/bin/findmnt -t nfs,nfs4 "$BACKUP" > /dev/null 2>&1;then
		NFS_READY=1
		break
	fi

	logger -t backup "NFS storage not ready, Retry $i/$MAX_RETRIES"

	sleep "RETRY_INTERVAL"
done

if [ "NFS_READY" -ne 1 ]; then
	logger -p user.err -t backup "NFS backup storage unavailable after retries"
	exit 1
fi

logger -t backup "Backup cleanup started: $DATE"

if ! find "$BACKUP" -mindepth 1 -maxdepth 1 -type d -mtime +2 -exec rm -rf -- {} +; then
	logger -p user.err -t backup "Old backup cleanup failed"
	exit 1
fi

logger -t backup "Backup cleanup complete: $DATE"
exit 0
