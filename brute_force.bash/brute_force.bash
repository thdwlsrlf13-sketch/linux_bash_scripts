#!/bin/bash

THRESHOLD=6
STATE_DIR="/var/lib/brute_force"
COOLDOWN=600
NOW=$(date +%s)
LOG_DATA=$(journalctl -u ssh --since "10 minutes ago")


echo "$LOG_DATA" | grep "Failed password" |
awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' |
sort |
uniq -c |
while read -r COUNT IP
do
	if [ "$COUNT" -ge "$THRESHOLD" ]; then

		STATE_FILE="$STATE_DIR/$IP"

		mkdir -p "$STATE_DIR"

		if [ -f "$STATE_FILE" ]; then
			LAST_ALERT=$(cat "$STATE_FILE")
		else
			LAST_ALERT=0
		fi

		ELAPSED=$((NOW - LAST_ALERT))

		if [ "$ELAPSED" -ge "$COOLDOWN" ]; then

			Message="[WARNING] Possible brute force: $IP ($COUNT failed attempts)"

			logger -p auth.warning -t brute-force "$MESSAGE"
			printf '%s\n' "$MESSAGE" | wall


			echo "$NOW" > "$STATE_FILE"
		fi
	fi
done

