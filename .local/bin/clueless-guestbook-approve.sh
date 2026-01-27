#!/bin/bash

# 1. Grab the ID
ENTRY_ID=$1

# 2. Validation: Ensure an ID was provided and is a number
if [[ -z "$ENTRY_ID" || ! "$ENTRY_ID" =~ ^[0-9]+$ ]]; then
    echo "Usage: ./clueless-guestbook-approve.sh <entry_id>"
    echo "Example: ./clueless-guestbook-approve.sh 105"
    exit 1
fi

# 3. Dynamically find the volume path
DB_PATH=$(podman volume inspect clueless_guestbook --format '{{ .Mountpoint }}')/clueless-guestbook.db

# 4. Run the update
# We use -cmd to turn on column headers so you can see the confirmation clearly
podman unshare sqlite3 "$DB_PATH" \
    "UPDATE entries SET isApproved = 1 WHERE id = $ENTRY_ID;" \
    "SELECT id, isApproved FROM entries WHERE id = $ENTRY_ID;"

echo "--- Process Complete ---"